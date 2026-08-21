import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
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
          final postApproval = ref.read(journeyControllerProvider).postApproval;
          if (postApproval != null) {
            final step = postApproval.workflow.currentStep;
            if (step == 'DIGILOCKER_KYC') {
              context.go('/loan/$effectiveLan/digilocker');
            } else if (step == 'ADDRESS_VERIFICATION') {
              context.go('/loan/$effectiveLan/address');
            } else {
              context.go('/loan/$effectiveLan/bank');
            }
          } else {
            context.go('/loan/$effectiveLan/digilocker');
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
    final customer = journeyState.customer;
    final isPreApproval = _checkIsPreApproval();

    final effectiveLan = widget.lan?.isNotEmpty == true
        ? widget.lan
        : (customer?.latestLan ?? customer?.platformLan);

    if (_isLoadingPreApproval || journeyState.isLoading) {
      return Scaffold(
        appBar: const AppHeader(title: 'Loan Offer'),
        body: const AppLoader(message: 'Loading loan offer...'),
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
          appBar: const AppHeader(title: 'Loan Offer'),
          body: const Center(child: Text('Offer not available.')),
        );
      }
      amount = ((_preApprovalOffer!['lenderApprovedAmount'] ?? _preApprovalOffer!['amount']) ?? 8000).toDouble();
      interestRate = ((_preApprovalOffer!['roi'] ?? _preApprovalOffer!['interestRate']) ?? 24.0).toDouble();
      lenderName = (_preApprovalOffer!['lenderName'] ?? 'Fintree Finance Private Limited').toString();
      allowedTenures = List<int>.from(_preApprovalOffer!['allowedTenures'] ?? [30, 45, 60]);
      isAccepted = _preApprovalOffer!['alreadySelected'] == true || _preApprovalOffer!['status'] == 'OFFER_SELECTED';
      processingFee = amount * 0.02;
      totalRepayment = amount + (amount * (interestRate / 100) * (_selectedTenureDays / 365));
    } else {
      final journey = journeyState.postApproval;
      final offer = journey?.offer;
      
      if (journey == null || offer == null) {
        return Scaffold(
          appBar: const AppHeader(title: 'Loan Offer'),
          body: const AppLoader(message: 'Loading approved loan offer...'),
        );
      }
      
      amount = (offer.approvedAmount ?? 50000).toDouble();
      interestRate = (offer.acceptedInterestRate ?? 18.0).toDouble();
      allowedTenures = offer.allowedTenures;
      isAccepted = offer.acceptedTenureDays != null;
      processingFee = (offer.acceptedProcessingFee ?? (amount * 0.02)).toDouble();
      totalRepayment = (offer.acceptedTotalRepayment ?? (amount + (amount * (interestRate / 100) * (_selectedTenureDays / 365)))).toDouble();
      lenderName = journey.lender.name;
    }

    final gst = processingFee * 0.18;
    final netDisbursal = amount - (processingFee + gst);

    return Scaffold(
      appBar: AppHeader(
        title: isPreApproval ? 'Pre-Approved Loan Offer' : 'Loan Offer Summary',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.primaryLightTeal,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sanctioned Loan Amount', style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
                          AppStatusBadge(status: 'APPROVED', label: isPreApproval ? 'Pre-Approved' : 'Offer Available'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyUtils.formatAmount(amount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDarkTeal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Lender: $lenderName', style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Select Repayment Tenure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: allowedTenures.map((tenure) {
                  final isSelected = _selectedTenureDays == tenure;
                  return ChoiceChip(
                    label: Text('$tenure Days'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textDarkPrimary,
                      fontWeight: FontWeight.w600,
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
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _row('Interest Rate', '$interestRate% p.a.'),
                      _row('Processing Fee', CurrencyUtils.formatAmount(processingFee)),
                      _row('GST on Processing Fee (18%)', CurrencyUtils.formatAmount(gst, showDecimals: true)),
                      _row('Net Disbursal Amount', CurrencyUtils.formatAmount(netDisbursal, showDecimals: true), isHighlight: true),
                      const Divider(height: 20),
                      _row('Total Repayment Obligation', CurrencyUtils.formatAmount(totalRepayment, showDecimals: true), isHighlight: true),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 32),
              if (isAccepted)
                AppButton(
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
              else
                AppButton(
                  text: isPreApproval ? 'Accept Offer & Proceed to next stage' : 'Accept Loan Offer',
                  isLoading: _isAccepting,
                  onPressed: _acceptOffer,
                  icon: Icons.check_circle_outline_rounded,
                ),
            ],
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
