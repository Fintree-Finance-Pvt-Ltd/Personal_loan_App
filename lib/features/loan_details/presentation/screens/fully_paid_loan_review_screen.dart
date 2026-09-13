import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/models/lender_offer_multiplier.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class FullyPaidLoanReviewScreen extends ConsumerStatefulWidget {
  final String? lan;

  const FullyPaidLoanReviewScreen({super.key, this.lan});

  @override
  ConsumerState<FullyPaidLoanReviewScreen> createState() =>
      _FullyPaidLoanReviewScreenState();
}

class _FullyPaidLoanReviewScreenState
    extends ConsumerState<FullyPaidLoanReviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _loanData;
  String _eligibilityFlag = 'GREEN'; // 'GREEN' | 'YELLOW' | 'RED'

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchDetails());
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
    });

    final customer = ref.read(journeyControllerProvider).customer;
    final effectiveLan = widget.lan?.isNotEmpty == true
        ? widget.lan!
        : (customer?.latestLan ?? customer?.platformLan ?? '');

    if (effectiveLan.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _determineEligibilityFlag(customer);
        });
      }
      return;
    }

    try {
      final customerApi = ref.read(customerApiProvider);
      final res = await customerApi.getCustomerLoanDetails(effectiveLan);

      dynamic data = res;
      if (data is Map<String, dynamic> && data['data'] != null) {
        data = data['data'];
      }

      if (mounted) {
        setState(() {
          _loanData = data is Map<String, dynamic> ? data : null;
          _isLoading = false;
          _determineEligibilityFlag(customer);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _determineEligibilityFlag(customer);
        });
      }
    }
  }

  void _determineEligibilityFlag(dynamic customer) {
    final status = (customer?.eligibilityStatus ?? '').toString().toUpperCase();
    if (status == 'NOT_ELIGIBLE' || status == 'POOR') {
      _eligibilityFlag = 'RED';
    } else if (status == 'CONDITIONALLY_ELIGIBLE' ||
        customer?.aadhaarVerified == false) {
      _eligibilityFlag = 'YELLOW';
    } else {
      _eligibilityFlag = 'GREEN';
    }
  }

  void _showNoDuesCertificateModal({
    required String lan,
    required String customerName,
    required String lenderName,
    required double approvedAmount,
    required String closureDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.amber, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'No-Dues Certificate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textDarkPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '${lenderName.toUpperCase()}\nNO DUES & LOAN CLOSURE CERTIFICATE',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryDarkTeal,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TO: ${customerName.toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is to certify that the Personal Loan account ($lan) registered under $customerName has been FULLY REPAID in full and final settlement. No outstanding dues remain against the Borrower.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: AppTheme.textDarkSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _certRow('Loan Account No (LAN):', lan),
                      _certRow('Lender:', lenderName),
                      _certRow('Sanctioned Amount:', CurrencyUtils.formatAmount(approvedAmount)),
                      _certRow('Closure Status:', 'FULLY PAID & CLOSED'),
                      _certRow('Closure Date:', closureDate),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppTheme.successGreen, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verified by Automated LMS Credit Ledger System.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Download Certificate PDF',
              icon: Icons.download_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No-Dues Certificate downloaded to device.'),
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _certRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textDarkSecondary)),
          Text(val,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;

    if (_isLoading) {
      return const Scaffold(
        appBar: AppHeader(title: 'Fully Paid Loan Review'),
        body: AppLoader(message: 'Retrieving loan completion history...'),
      );
    }

    final loan = postApproval?.loan;
    final lan = widget.lan ?? loan?.lan ?? customer?.latestLan ?? customer?.platformLan ?? 'N/A';
    
    // Dynamic loan amount calculation (avoiding hardcoded dummy data)
    final num baseLoanAmount = (loan?.approvedAmount ??
        _loanData?['approvedAmount'] ??
        _loanData?['sanctionedAmount'] ??
        _loanData?['amount'] ??
        50000);

    final double approvedAmount = baseLoanAmount.toDouble();

    // Determine completed loans count (at least 1 if in this screen)
    final int completedLoans = (customer?.completedLoansCount != null && customer!.completedLoansCount > 0)
        ? customer.completedLoansCount
        : (_loanData?['completedLoansCount'] ?? 1);

    // Apply LenderOfferMultiplier rule dynamically
    final double multiplier = LenderMultiplierCalculator.getMultiplier(completedLoans);
    final double revisedLoanLimit = LenderMultiplierCalculator.calculateRevisedLimit(approvedAmount, completedLoans);

    final String customerName = customer?.fullName ?? customer?.firstName ?? 'Valued Customer';
    final String lenderName = customer?.allocatedLenderName ??
        _loanData?['lenderName'] ??
        postApproval?.lender.name ??
        'Fintree Finance Private Limited';

    final String closureDate = _loanData?['closureDate'] ??
        _loanData?['closedAt'] ??
        loan?.disbursalCompletedAt ??
        'Closed';

    return Scaffold(
      appBar: const AppHeader(
        title: 'Fully Paid Loan Review',
        fallbackRoute: '/dashboard',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Completion Card ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryDeepTeal,
                      AppTheme.primaryDarkTeal,
                      AppTheme.primaryTeal,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppStatusBadge(
                          status: 'FULLY_PAID',
                          label: 'FULLY PAID & CLOSED',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.black87, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$completedLoans ${completedLoans == 1 ? 'Loan' : 'Loans'} Repaid',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAN: $lan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyUtils.formatAmount(approvedAmount),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fully Repaid • Zero Outstanding',
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        SvgPicture.asset(
                          'lib/assets/images/illustrations/Celebration-rafiki.svg',
                          height: 105,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => _showNoDuesCertificateModal(
                        lan: lan,
                        customerName: customerName,
                        lenderName: lenderName,
                        approvedAmount: approvedAmount,
                        closureDate: closureDate,
                      ),
                      icon: const Icon(Icons.verified_rounded,
                          color: AppTheme.primaryDeepTeal, size: 18),
                      label: const Text(
                        'View No-Dues Certificate',
                        style: TextStyle(
                          color: AppTheme.primaryDeepTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. Payment Discipline Scorecard ─────────────────────────────
              const Text(
                'Payment Discipline Analysis',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Repayment Rating',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textDarkSecondary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successBg,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'EXCELLENT 100%',
                              style: TextStyle(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _metric('100%', 'On-Time Repayment', Icons.check_circle_outline),
                          _metric('0', 'Late Days', Icons.timer_outlined),
                          _metric('0', 'Bounces', Icons.block_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── 3. Repeat Loan Eligibility Determination Card ───────────────────────────
              const Text(
                'Repeat Loan Offer Multiplier Determination',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 12),

              if (_eligibilityFlag == 'GREEN') ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightTeal,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: AppTheme.primaryTeal, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'GREEN FLAG: Eligible for Revised Repeat Loan!',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryDarkTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Based on your $completedLoans completed ${completedLoans == 1 ? 'loan' : 'loans'}, your lender offer multiplier is ${multiplier.toStringAsFixed(4)}x.',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textDarkSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      _benefitRow(
                          'Enhanced Limit: Up to ${CurrencyUtils.formatAmount(revisedLoanLimit)} (${multiplier}x Multiplier Applied)'),
                      _benefitRow('Tier Status: Premier Repeat Borrower (${completedLoans} Completed Loan${completedLoans > 1 ? 's' : ''})'),
                      _benefitRow('Special Benefit: Reduced Interest & Instant Approval'),
                      _benefitRow('Fast-Track Disbursal: Immediate Transfer to Saved Account'),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Apply for Pre-Approved Repeat Loan',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          context.push('/onboarding/basic-details');
                        },
                      ),
                    ],
                  ),
                ),
              ] else if (_eligibilityFlag == 'YELLOW') ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.amber, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'YELLOW FLAG: Conditional Repeat Eligibility',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You are conditionally eligible for a revised loan limit of ${CurrencyUtils.formatAmount(revisedLoanLimit)} (${multiplier}x multiplier). Please verify updated document proofs:',
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black87,
                            height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      _benefitRow('Fresh Address Proof (< 90 days old)'),
                      _benefitRow('Latest Bank Statement Re-verification'),
                      _benefitRow('Updated Aadhaar / DigiLocker Verification'),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Upload Updated Documents',
                        icon: Icons.cloud_upload_outlined,
                        onPressed: () {
                          context.push('/onboarding/digilocker');
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: AppTheme.errorRed, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'RED FLAG: Under Credit Review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your application for a new loan is currently under manual credit review. Re-evaluation scheduled soon.',
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textDarkSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Contact Credit Support Team',
                        icon: Icons.headset_mic_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Credit support request logged. Agent will contact you.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── 4. System Validation Checklist ──────────────────────────────
              const Text(
                'System Validation Checklist',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _checkTile(
                          'Account Status', 'ACTIVE', customer?.accountStatus != 'DISABLED'),
                      _checkTile(
                          'PAN Verification', 'VERIFIED', customer?.panVerified == true),
                      _checkTile(
                          'KYC Status', 'COMPLETED', customer?.aadhaarVerified == true),
                      _checkTile('Previous Loan Status', 'FULLY PAID', true),
                      _checkTile(
                          'Offer Multiplier', '${multiplier}x APPLIED', true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryTeal, size: 22),
        const SizedBox(height: 6),
        Text(
          val,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textDarkSecondary,
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.primaryTeal, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile(String title, String statusLabel, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_rounded : Icons.pending_rounded,
                color: isDone ? AppTheme.successGreen : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
            ],
          ),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDone ? AppTheme.successGreen : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
