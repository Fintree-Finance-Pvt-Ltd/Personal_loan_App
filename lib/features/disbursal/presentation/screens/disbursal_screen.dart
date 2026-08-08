import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
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

  void _requestDisbursal() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/disbursal/request',
        data: {'customerId': customerId},
      );

      // Sync state then navigate to dashboard
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postApproval = ref.watch(journeyControllerProvider).postApproval;
    final loan = postApproval?.loan;
    final bank = postApproval?.bank;
    final offer = postApproval?.offer;
    final netAmount = (offer?.approvedAmount?.toDouble() ?? 0) -
        (offer?.acceptedProcessingFee?.toDouble() ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F8),
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
                      Color(0xFF033F45),
                      Color(0xFF007C73),
                      Color(0xFF13AA9B),
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
                                const Text(
                                  'Disbursal Request',
                                  style: TextStyle(
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
                          'Net Amount to be Credited',
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── All milestones complete banner ──────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppTheme.successGreen, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: AppTheme.successGreen, size: 28),
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
                              'Your loan is ready for instant transfer to your bank account.',
                              style: TextStyle(
                                  color: AppTheme.successDarkGreen,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Loan Summary Card ───────────────────────────────────
                _sectionCard(
                  title: 'Loan Summary',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    _row('Loan Account No.',
                        loan?.lan ?? widget.lan),
                    _row('Approved Amount',
                        CurrencyUtils.formatAmount(
                            loan?.approvedAmount ?? 0)),
                    _row('Processing Fee',
                        CurrencyUtils.formatAmount(
                            offer?.acceptedProcessingFee ?? 0)),
                    _divider(),
                    _row(
                      'Net Disbursal Amount',
                      CurrencyUtils.formatAmount(netAmount),
                      highlight: true,
                    ),
                    _row(
                      'Tenure',
                      offer?.acceptedTenureDays != null
                          ? '${offer!.acceptedTenureDays} days'
                          : '—',
                    ),
                    _row(
                      'Total Repayment',
                      CurrencyUtils.formatAmount(
                          offer?.acceptedTotalRepayment ?? 0),
                    ),
                    _row(
                      'Interest Rate',
                      offer?.acceptedInterestRate != null
                          ? '${offer!.acceptedInterestRate}% p.a.'
                          : '—',
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
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── CTA ─────────────────────────────────────────────────
                if (_isRequesting)
                  const AppLoader(
                      message:
                          'Submitting disbursal request...')
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
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppTheme.primaryTeal
                    : AppTheme.textDarkPrimary,
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
