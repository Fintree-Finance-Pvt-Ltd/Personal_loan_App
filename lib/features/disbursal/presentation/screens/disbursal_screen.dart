import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class DisbursalScreen extends ConsumerStatefulWidget {
  final String lan;
  const DisbursalScreen({super.key, required this.lan});

  @override
  ConsumerState<DisbursalScreen> createState() => _DisbursalScreenState();
}

class _DisbursalScreenState extends ConsumerState<DisbursalScreen> {
  bool _isRequesting = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _checkAndStartPolling() {
    final postApproval = ref.read(journeyControllerProvider).postApproval;
    final loan = postApproval?.loan;
    final workflow = postApproval?.workflow;
    final currentStep = workflow?.currentStep ?? '';
    final disbursalStatus = loan?.disbursalStatus ?? '';

    final isProcessing = currentStep == 'DISBURSAL_PROCESSING' ||
        disbursalStatus == 'DISBURSAL_PROCESSING' ||
        disbursalStatus == 'DISBURSAL_REQUESTED' ||
        loan?.status == 'DISBURSAL_PROCESSING';

    if (isProcessing) {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      final postApproval = ref.read(journeyControllerProvider).postApproval;
      final loan = postApproval?.loan;
      final workflow = postApproval?.workflow;

      final isDisbursed = workflow?.currentStep == 'DISBURSED' ||
          loan?.disbursalStatus == 'DISBURSED' ||
          loan?.status == 'DISBURSED';

      if (isDisbursed) {
        timer.cancel();
      }
    });
  }

  void _requestDisbursal() async {
    final postApproval = ref.read(journeyControllerProvider).postApproval;
    final workflow = postApproval?.workflow;

    final missingSteps = _getMissingSteps(workflow);
    if (missingSteps.isNotEmpty) {
      setState(() {
        _errorMessage = 'Please complete all pending post-approval steps before requesting disbursal.';
      });
      return;
    }

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final customerApi = ref.read(customerApiProvider);
      await customerApi.requestDisbursal(widget.lan);

      // Refresh state from backend
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        // Navigate to Loan Details screen to track disbursal & view loan agreement summary
        context.go('/loan/${widget.lan}/loan-details');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  List<Map<String, String>> _getMissingSteps(dynamic workflow) {
    if (workflow == null) return [];
    final List<Map<String, String>> list = [];
    if (workflow.offerAccepted != true) {
      list.add({'id': 'APPROVAL_SUMMARY', 'name': 'Offer Acceptance', 'route': '/loan/${widget.lan}/offer'});
    }
    if (workflow.digilockerVerified != true) {
      list.add({'id': 'DIGILOCKER_KYC', 'name': 'Aadhaar KYC', 'route': '/loan/${widget.lan}/digilocker'});
    }
    if (workflow.addressConfirmed != true) {
      list.add({'id': 'ADDRESS_CONFIRMATION', 'name': 'Address Confirmation', 'route': '/loan/${widget.lan}/address'});
    }
    if (workflow.bankVerified != true) {
      list.add({'id': 'BANK_VERIFICATION', 'name': 'Bank Account Verification', 'route': '/loan/${widget.lan}/bank'});
    }
    if (workflow.kfsAccepted != true) {
      list.add({'id': 'KFS_ACCEPTANCE', 'name': 'Key Fact Statement (KFS)', 'route': '/loan/${widget.lan}/kfs'});
    }
    if (workflow.mandateCompleted != true) {
      list.add({'id': 'EMANDATE', 'name': 'e-Mandate Setup', 'route': '/loan/${widget.lan}/mandate'});
    }
    if (workflow.esignCompleted != true) {
      list.add({'id': 'ESIGN', 'name': 'e-Sign Loan Agreement', 'route': '/loan/${widget.lan}/esign'});
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final postApproval = ref.watch(journeyControllerProvider).postApproval;
    final loan = postApproval?.loan;
    final bank = postApproval?.bank;
    final offer = postApproval?.offer;
    final workflow = postApproval?.workflow;

    final netAmount = (offer?.approvedAmount?.toDouble() ?? 0) -
        (offer?.acceptedProcessingFee?.toDouble() ?? 0);

    final missingSteps = _getMissingSteps(workflow);
    final bool allCompleted = missingSteps.isEmpty;

    final currentStep = workflow?.currentStep ?? '';
    final disbursalStatus = loan?.disbursalStatus ?? '';
    final isDisbursed = currentStep == 'DISBURSED' ||
        disbursalStatus == 'DISBURSED' ||
        loan?.status == 'DISBURSED';

    final isDisbursalProcessing = currentStep == 'DISBURSAL_PROCESSING' ||
        disbursalStatus == 'DISBURSAL_PROCESSING' ||
        disbursalStatus == 'DISBURSAL_REQUESTED' ||
        loan?.status == 'DISBURSAL_PROCESSING';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryDeepTeal,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryDeepTeal,
                      AppTheme.primaryDarkTeal,
                      AppTheme.primaryTeal,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDisbursed
                                      ? 'Loan Disbursed'
                                      : isDisbursalProcessing
                                          ? 'Disbursal Processing'
                                          : 'Disbursal Request',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  loan?.lan ?? widget.lan,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isDisbursed ? 'Net Credited Amount' : 'Net Amount to be Credited',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          CurrencyUtils.formatAmount(netAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leadingWidth: 56,
            leading: const AppBackButton(isDark: true),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Case A: Disbursed Banner ──────────────────────────────
                if (isDisbursed) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.successGreen, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.successGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Loan Disbursed Successfully!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successDarkGreen,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'The funds have been transferred to your bank account via LMS.',
                                style: TextStyle(
                                  color: AppTheme.successDarkGreen.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]
                // ── Case B: Processing Banner ────────────────────────────
                else if (isDisbursalProcessing) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Disbursal Processing & LMS Integration',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Your request was dispatched to LMS. Awaiting bank payout confirmation webhook.',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]
                // ── Case C: Incomplete Steps Warning ─────────────────────
                else if (!allCompleted) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Pending Prerequisite Steps',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Disbursal cannot be initiated until all preceding loan steps are saved in DB:',
                          style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ...missingSteps.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  step['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.textDarkPrimary,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => context.push(step['route']!),
                                  child: Row(
                                    children: const [
                                      Text(
                                        'Complete Step',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryTeal),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]
                // ── Case D: Ready Banner ─────────────────────────────────
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.successGreen, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'All milestones completed!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successDarkGreen,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Your loan is ready for instant LMS disbursal transfer to your bank account.',
                                style: TextStyle(color: AppTheme.successDarkGreen, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Loan Summary Card ───────────────────────────────────
                _sectionCard(
                  title: 'Loan Summary',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    _row('Loan Account No.', loan?.lan ?? widget.lan),
                    _row('Approved Amount', CurrencyUtils.formatAmount(loan?.approvedAmount ?? 0)),
                    _row('Processing Fee', CurrencyUtils.formatAmount(offer?.acceptedProcessingFee ?? 0)),
                    _divider(),
                    _row(
                      'Net Disbursal Amount',
                      CurrencyUtils.formatAmount(netAmount),
                      highlight: true,
                    ),
                    _row(
                      'Tenure',
                      offer?.acceptedTenureDays != null ? '${offer!.acceptedTenureDays} days' : '—',
                    ),
                    _row(
                      'Total Repayment',
                      CurrencyUtils.formatAmount(offer?.acceptedTotalRepayment ?? 0),
                    ),
                    _row(
                      'Interest Rate',
                      offer?.acceptedInterestRate != null ? '${offer!.acceptedInterestRate}% p.a.' : '—',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Bank Account Card ───────────────────────────────────
                _sectionCard(
                  title: 'Destination Account',
                  icon: Icons.account_balance_rounded,
                  children: [
                    _row('Bank', bank?.bankName ?? '—'),
                    _row('Account Holder', bank?.accountHolderName ?? '—'),
                    _row('Account No.', _maskAccount(bank?.accountMasked)),
                    _row('IFSC', bank?.ifsc ?? '—'),
                    _row('Account Type', bank?.accountType ?? 'SAVINGS'),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Error message ───────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── CTA Buttons ─────────────────────────────────────────
                if (isDisbursed || isDisbursalProcessing)
                  AppButton(
                    text: 'View Active Loan Details & Repayment',
                    onPressed: () => context.go('/loan/${widget.lan}/loan-details'),
                    icon: Icons.assignment_rounded,
                  )
                else if (_isRequesting)
                  const AppLoader(message: 'Initiating Disbursal & LMS API Call...')
                else
                  AppButton(
                    text: 'Request Instant Disbursal',
                    onPressed: _requestDisbursal,
                    icon: Icons.flash_on_rounded,
                  ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryTeal, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
              )),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(height: 1),
      );

  String _maskAccount(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.length <= 4) return raw;
    return 'XXXX XXXX ${raw.substring(raw.length - 4)}';
  }
}
