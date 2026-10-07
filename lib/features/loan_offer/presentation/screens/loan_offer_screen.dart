import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/lender_offer_multiplier.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/animated_page.dart';
import '../../../../core/widgets/journey_progress.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class LoanOfferScreen extends ConsumerStatefulWidget {
  final String? lan;
  final bool isOnboarding;

  const LoanOfferScreen({super.key, this.lan, this.isOnboarding = false});

  @override
  ConsumerState<LoanOfferScreen> createState() => _LoanOfferScreenState();
}

class _LoanOfferScreenState extends ConsumerState<LoanOfferScreen> {
  int _selectedTenureDays = 60;
  bool _isAccepting = false;
  String? _errorMessage;
  bool _isLoadingPreApproval = false;
  Map<String, dynamic>? _preApprovalOffer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadOfferData();
    });
  }

  bool _checkIsPreApproval() {
    final customer = ref.read(journeyControllerProvider).customer;
    return widget.isOnboarding ||
        customer?.nextPermittedStep == 'PRE_APPROVAL_OFFER_SELECTION' ||
        customer?.latestApplicationStatus == 'LENDER_PRE_APPROVED';
  }

  void _loadOfferData() async {
    final customer = ref.read(journeyControllerProvider).customer;
    final isPreApproval = _checkIsPreApproval();

    final effectiveLan = widget.lan?.isNotEmpty == true
        ? widget.lan
        : (customer?.latestLan ?? customer?.platformLan);

    if (isPreApproval) {
      // Fetch pre-approval offer
      if (effectiveLan != null && effectiveLan.isNotEmpty) {
        setState(() => _isLoadingPreApproval = true);
        try {
          final customerApi = ref.read(customerApiProvider);
          final res = await customerApi.getPreApprovalOffer(effectiveLan);
          
          dynamic rawData = res;
          if (rawData is Map<String, dynamic> && rawData['data'] != null) {
            rawData = rawData['data'];
          }
          
          setState(() {
            _preApprovalOffer = rawData is Map<String, dynamic> ? rawData : {};
            final allowedTenures = List<int>.from(_preApprovalOffer?['allowedTenures'] ?? []);
            if (allowedTenures.isNotEmpty) {
              _selectedTenureDays = _preApprovalOffer?['selectedTenure'] ?? allowedTenures.first;
            }
          });
        } catch (e) {
          String msg = e.toString();
          if (e is DioException) {
            final apiClient = ref.read(apiClientProvider);
            msg = apiClient.handleError(e).message;
          } else if (e is AppException) {
            msg = e.message;
          } else if (msg.startsWith('Exception: ')) {
            msg = msg.substring(11);
          }
          setState(() {
            _errorMessage = 'Failed to load pre-approval offer: $msg';
          });
        } finally {
          if (mounted) setState(() => _isLoadingPreApproval = false);
        }
      }
    } else {
      // Regular post-approval offer
      final offer = ref.read(journeyControllerProvider).postApproval?.offer;
      if (offer != null && offer.allowedTenures.isNotEmpty) {
        setState(() {
          _selectedTenureDays = offer.acceptedTenureDays ?? offer.allowedTenures.first;
        });
      }
    }
  }

  void _acceptOffer() async {
    final customer = ref.read(journeyControllerProvider).customer;
    final customerId = customer?.id;
    if (customerId == null) return;

    final effectiveLan = widget.lan?.isNotEmpty == true
        ? widget.lan
        : (customer?.latestLan ?? customer?.platformLan);

    if (effectiveLan == null || effectiveLan.isEmpty) {
      setState(() {
        _errorMessage = 'Loan account LAN is missing.';
      });
      return;
    }

    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final isPreApproval = _checkIsPreApproval();
      
      if (isPreApproval) {
        final customerApi = ref.read(customerApiProvider);
        await customerApi.selectPreApprovalOffer(effectiveLan, _selectedTenureDays);
        
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        if (mounted) {
          final customerState = ref.read(journeyControllerProvider).customer;
          final nextStep = customerState?.nextPermittedStep;
          final isProcessing = nextStep == 'LENDER_DECISION_PROCESSING' ||
              nextStep == 'LENDER_CREATE_PROCESSING' ||
              nextStep == 'APPROVAL_PROCESSING' ||
              customerState?.latestApplicationStatus == 'SUBMITTED' ||
              customerState?.latestApplicationStatus == 'PENDING_CREDIT_REVIEW';

          if (isProcessing) {
            context.go('/application/status');
          } else {
            final postApproval = ref.read(journeyControllerProvider).postApproval;
            final step = postApproval?.workflow.currentStep;
            if (step == 'KFS_ACCEPTANCE') {
              context.go('/loan/$effectiveLan/kfs');
            } else if (step == 'EMANDATE') {
              context.go('/loan/$effectiveLan/mandate');
            } else if (step == 'ESIGN') {
              context.go('/loan/$effectiveLan/esign');
            } else {
              context.go('/loan/$effectiveLan/bank');
            }
          }
        }
      } else {
        // Post-approval accept flow
        await apiClient.post(
          '/customer/loans/$effectiveLan/offer/accept',
          data: {
            'customerId': customerId,
            'tenureDays': _selectedTenureDays,
          },
        );

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();

        if (mounted) {
          if (widget.isOnboarding) {
            context.push('/onboarding/review');
          } else {
            context.push('/loan/$effectiveLan/digilocker');
          }
        }
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        final apiClient = ref.read(apiClientProvider);
        msg = apiClient.handleError(e).message;
      } else if (e is AppException) {
        msg = e.message;
      } else if (msg.startsWith('Exception: ')) {
        msg = msg.substring(11);
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final tr = ref.watch(appLocalizationsProvider);
    final customer = journeyState.customer;
    final isPreApproval = _checkIsPreApproval();

    final effectiveLan = widget.lan?.isNotEmpty == true
        ? widget.lan
        : (customer?.latestLan ?? customer?.platformLan);

    if (_isLoadingPreApproval || journeyState.isLoading) {
      return Scaffold(
        appBar: AppHeader(title: tr.tr('loan_offer_title')),
        body: const SafeArea(
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(20.0),
            child: OfferSkeletonCard(),
          ),
        ),
      );
    }

    double amount = 0;
    double interestRate = 18.0;
    double processingFee = 0;
    List<int> allowedTenures = [];
    bool isAccepted = false;
    double totalRepayment = 0;
    String lenderName = 'Fintree Finance Private Limited';

    if (isPreApproval) {
      if (_preApprovalOffer == null) {
        return Scaffold(
          appBar: AppHeader(title: tr.tr('loan_offer_title')),
          body: const SafeArea(
            child: Center(
              child: Text(
                'Offer not available at this moment.',
                style: TextStyle(color: AppTheme.textDarkSecondary),
              ),
            ),
          ),
        );
      }
      final num rawAmount = _preApprovalOffer!['lenderApprovedAmount'] ?? _preApprovalOffer!['amount'] ?? 50000;
      amount = rawAmount.toDouble();
      interestRate = ((_preApprovalOffer!['roi'] ?? _preApprovalOffer!['interestRate']) ?? 18.0).toDouble();
      lenderName = (customer?.allocatedLenderName ?? _preApprovalOffer!['lenderName'] ?? 'Allocated Lender').toString();
      allowedTenures = List<int>.from(_preApprovalOffer!['allowedTenures'] ?? [30, 45, 60]);
      isAccepted = _preApprovalOffer!['alreadySelected'] == true || _preApprovalOffer!['status'] == 'OFFER_SELECTED';
      processingFee = (_preApprovalOffer!['processingFee'] ?? (amount * 0.02)).toDouble();
      totalRepayment = (_preApprovalOffer!['totalRepaymentAmount'] ?? (amount + (amount * (interestRate / 100) * (_selectedTenureDays / 365)))).toDouble();
    } else {
      final journey = journeyState.postApproval;
      final offer = journey?.offer;
      
      if (journey == null || offer == null) {
        return Scaffold(
          appBar: AppHeader(title: tr.tr('loan_offer_title')),
          body: const SafeArea(
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.0),
              child: OfferSkeletonCard(),
            ),
          ),
        );
      }
      
      final num rawAmount = offer.approvedAmount ?? journey.loan.approvedAmount ?? 50000;
      amount = rawAmount.toDouble();
      interestRate = (offer.acceptedInterestRate ?? 18.0).toDouble();
      allowedTenures = offer.allowedTenures;
      isAccepted = offer.acceptedTenureDays != null;
      processingFee = (offer.acceptedProcessingFee ?? (amount * 0.02)).toDouble();
      totalRepayment = (offer.acceptedTotalRepayment ?? (amount + (amount * (interestRate / 100) * (_selectedTenureDays / 365)))).toDouble();
      lenderName = customer?.allocatedLenderName ?? journey.lender.name;
    }

    final gst = processingFee * 0.18;
    final netDisbursal = amount - (processingFee + gst);

    return Scaffold(
      appBar: AppHeader(
        title: tr.tr('loan_offer_title'),
      ),
      body: SafeArea(
        child: AnimatedPage(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Continuous Journey Progress Header
                AnimatedSection(
                  delay: const Duration(milliseconds: 50),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: JourneyProgress(
                      currentStep: isPreApproval ? LoanJourneyStep.preApproval : LoanJourneyStep.offer,
                      compact: true,
                    ),
                  ),
                ),

                // 2. Main Offer Card
                AnimatedSection(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryTeal.withValues(alpha: 0.08),
                          AppTheme.primaryTeal.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sanctioned Loan Amount',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDarkSecondary,
                              ),
                            ),
                            AppStatusBadge(
                              status: 'APPROVED',
                              label: isPreApproval ? 'Pre-Approved' : 'Offer Available',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          CurrencyUtils.formatAmount(amount),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDarkTeal,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_balance_rounded, size: 14, color: AppTheme.textDarkSecondary),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Lender: $lenderName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textDarkSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if ((customer?.completedLoansCount ?? 0) > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 14, color: AppTheme.primaryTeal),
                                const SizedBox(width: 6),
                                Text(
                                  '${LenderMultiplierCalculator.getMultiplier(customer!.completedLoansCount)}x Multiplier Applied (${customer.completedLoansCount} Completed)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryDarkTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Repayment Tenure Selector
                AnimatedSection(
                  delay: const Duration(milliseconds: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Repayment Tenure',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDarkPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: allowedTenures.map((tenure) {
                          final isSelected = _selectedTenureDays == tenure;
                          return ChoiceChip(
                            label: Text('$tenure Days'),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryTeal,
                            backgroundColor: AppTheme.surfaceWhite,
                            elevation: isSelected ? 2 : 0,
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : AppTheme.borderLight,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textDarkPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 13,
                            ),
                            onSelected: isAccepted
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(() => _selectedTenureDays = tenure);
                                    }
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Financial Breakdown Card
                AnimatedSection(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _row('Interest Rate', '$interestRate% p.a.'),
                        _row('Processing Fee', CurrencyUtils.formatAmount(processingFee)),
                        _row('GST on Fee (18%)', CurrencyUtils.formatAmount(gst, showDecimals: true)),
                        _row('Net Disbursal Amount', CurrencyUtils.formatAmount(netDisbursal, showDecimals: true), isHighlight: true),
                        const Divider(height: 22, color: AppTheme.borderLight),
                        _row('Total Repayment Obligation', CurrencyUtils.formatAmount(totalRepayment, showDecimals: true), isHighlight: true),
                      ],
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AnimatedSection(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // 5. CTA Button
                AnimatedSection(
                  delay: const Duration(milliseconds: 250),
                  child: isAccepted
                      ? AppButton(
                          text: isPreApproval 
                              ? 'Offer Selected - View Status' 
                              : (widget.isOnboarding ? 'Offer Accepted - Continue to Review' : 'Offer Accepted - Continue to KYC'),
                          onPressed: () {
                            if (isPreApproval) {
                              context.push('/application/status');
                            } else if (widget.isOnboarding) {
                              context.push('/onboarding/review');
                            } else {
                              context.push('/loan/$effectiveLan/digilocker');
                            }
                          },
                          icon: Icons.arrow_forward_rounded,
                        )
                      : AppButton(
                          text: isPreApproval ? 'Accept Offer & Proceed to Next Stage' : 'Accept Loan Offer',
                          isLoading: _isAccepting,
                          onPressed: _acceptOffer,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
