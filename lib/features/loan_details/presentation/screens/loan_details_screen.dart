import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class LoanDetailsScreen extends ConsumerWidget {
  final String lan;
  const LoanDetailsScreen({super.key, required this.lan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postApproval = ref.watch(journeyControllerProvider).postApproval;
    final loan = postApproval?.loan;
    final offer = postApproval?.offer;
    final bank = postApproval?.bank;
    final customer = ref.watch(journeyControllerProvider).customer;
    final lender = postApproval?.lender;
    final isDisbursed = loan?.disbursalStatus == 'DISBURSED' ||
        loan?.disbursalCompletedAt != null;

    final approvedAmount = loan?.approvedAmount?.toDouble() ?? 0;
    final processingFee = offer?.acceptedProcessingFee?.toDouble() ?? 0;
    final netDisbursalAmount = approvedAmount - processingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F8),
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.primaryDeepTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
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
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isDisbursed
                                        ? Colors.greenAccent.withOpacity(0.25)
                                        : Colors.orangeAccent.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDisbursed
                                          ? Colors.greenAccent
                                          : Colors.orangeAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isDisbursed ? '✓ DISBURSED' : '⏳ PROCESSING',
                                    style: TextStyle(
                                      color: isDisbursed
                                          ? Colors.greenAccent
                                          : Colors.orangeAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              customer?.fullName ?? 'Your Loan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  loan?.lan ?? lan,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: loan?.lan ?? lan));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('LAN copied to clipboard'),
                                          duration: Duration(seconds: 2)),
                                    );
                                  },
                                  child: Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white.withOpacity(0.6),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              CurrencyUtils.formatAmount(approvedAmount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Approved Loan Amount',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Status Banner ───────────────────────────────────────
                if (!isDisbursed)
                  _creditingSoonBanner()
                else
                  _disbursalSuccessCard(
                    loan?.disbursalAmount ?? netDisbursalAmount,
                    loan?.disbursalUtr,
                    loan?.disbursalCompletedAt,
                    loan?.disbursalDate,
                  ),
                const SizedBox(height: 16),

                // ── Loan Details ────────────────────────────────────────
                _sectionCard(
                  title: 'Loan Details',
                  icon: Icons.receipt_long_rounded,
                  children: [
                    _row('Loan Account No.', loan?.lan ?? lan),
                    _row('Application No.', loan?.applicationNumber ?? '—'),
                    _row('Lender',
                        lender?.name ?? 'Fintree Finance Private Limited'),
                    _row('Approved On', _formatDate(loan?.approvedAt)),
                    _row('Loan Status', loan?.status ?? '—'),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Offer Summary ───────────────────────────────────────
                _sectionCard(
                  title: 'Offer Summary',
                  icon: Icons.local_offer_rounded,
                  children: [
                    _row('Approved Amount',
                        CurrencyUtils.formatAmount(approvedAmount)),
                    _row('Processing Fee',
                        CurrencyUtils.formatAmount(processingFee)),
                    _rowDivider(),
                    _row(
                      'Net Disbursal Amount',
                      CurrencyUtils.formatAmount(netDisbursalAmount),
                      highlight: true,
                    ),
                    _row(
                      'Tenure',
                      offer?.acceptedTenureDays != null
                          ? '${offer!.acceptedTenureDays} days'
                          : '—',
                    ),
                    _row(
                      'Interest Rate',
                      offer?.acceptedInterestRate != null
                          ? '${offer!.acceptedInterestRate}% p.a.'
                          : '—',
                    ),
                    _row(
                      'EMI / Total Repayment',
                      CurrencyUtils.formatAmount(
                          offer?.acceptedTotalRepayment ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Bank Account ────────────────────────────────────────
                _sectionCard(
                  title: 'Bank Account',
                  icon: Icons.account_balance_rounded,
                  children: [
                    _row('Bank Name', bank?.bankName ?? '—'),
                    _row('Account Holder', bank?.accountHolderName ?? '—'),
                    _row('Account No.', _maskAcc(bank?.accountMasked)),
                    _row('IFSC Code', bank?.ifsc ?? '—'),
                    _row('Account Type', bank?.accountType ?? 'SAVINGS'),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Milestones ──────────────────────────────────────────
                _sectionCard(
                  title: 'Journey Milestones',
                  icon: Icons.checklist_rounded,
                  children: [
                    _milestone('Offer Accepted',
                        postApproval?.workflow.offerAccepted ?? false),
                    _milestone('Aadhaar KYC Verified',
                        postApproval?.workflow.digilockerVerified ?? false),
                    _milestone('Address Confirmed',
                        postApproval?.workflow.addressConfirmed ?? false),
                    _milestone('Bank Account Verified',
                        postApproval?.workflow.bankVerified ?? false),
                    _milestone('KFS Accepted',
                        postApproval?.workflow.kfsAccepted ?? false),
                    _milestone('e-Mandate Registered',
                        postApproval?.workflow.mandateCompleted ?? false),
                    _milestone('Agreement e-Signed',
                        postApproval?.workflow.esignCompleted ?? false),
                    _milestone('Loan Disbursed', isDisbursed),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Back to dashboard ───────────────────────────────────
                OutlinedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryTeal,
                    side: const BorderSide(color: AppTheme.primaryTeal),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditingSoonBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E6), Color(0xFFFFF3CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6A817), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE6A817).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF9E6A00),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your loan amount will be\ncredited shortly!',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A4F00),
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disbursal is being processed. Funds will arrive in your bank account within a few minutes.',
                  style: TextStyle(
                    color: const Color(0xFF9E6A00).withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disbursalSuccessCard(
    num amount,
    String? utr,
    String? completedAt,
    String? disbursalDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successGreen, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successGreen.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Disbursed Successfully!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successDarkGreen,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Funds transferred to your bank account',
                    style: TextStyle(
                      color: AppTheme.successDarkGreen.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _infoRow('Disbursed Amount',
                    CurrencyUtils.formatAmount(amount),
                    bold: true),
                if (utr != null && utr.isNotEmpty)
                  _infoRow('UTR Reference', utr),
                if (completedAt != null)
                  _infoRow('Disbursed On', _formatDate(completedAt)),
                if (disbursalDate != null)
                  _infoRow('Value Date', disbursalDate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textDarkSecondary)),
          Text(val,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: AppTheme.successDarkGreen,
              )),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textDarkSecondary)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Divider(height: 1),
      );

  Widget _milestone(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppTheme.successGreen : AppTheme.borderLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check : Icons.remove,
              color: done ? Colors.white : AppTheme.textMuted,
              size: 13,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: done ? AppTheme.textDarkPrimary : AppTheme.textDarkSecondary,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            done ? 'Completed' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              color: done ? AppTheme.successGreen : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _maskAcc(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    if (raw.length <= 4) return raw;
    return 'XXXX XXXX ${raw.substring(raw.length - 4)}';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
