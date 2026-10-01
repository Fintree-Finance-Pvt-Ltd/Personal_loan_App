import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/models/referral_model.dart';
import '../../../../core/providers/referral_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loader.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  String? _selectedFilter; // null = All, 'DISBURSED', 'PENDING'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(referralProvider.notifier).fetchDashboard();
    });
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Referral code "$code" copied to clipboard!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareReferralLink(String code, String shareLink) {
    final linkToShare = shareLink.isNotEmpty
        ? shareLink
        : 'https://fin-tree.fintreefinance.com/customer/login?ref=$code';
    final shareMessage =
        'Hey! Apply for instant digital personal loans on Fin-Tree with zero physical paperwork! 🚀\n\n'
        'Use my referral code *$code* or click this link to join:\n$linkToShare\n\n'
        'Invite Peers, Slash Assessment & Processing Fees!';

    Share.share(shareMessage, subject: 'Join Fin-Tree with referral code $code');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralProvider);
    final dashboard = state.dashboard;

    final historyItems = dashboard.referralHistory.where((item) {
      if (_selectedFilter == 'DISBURSED') {
        return item.isDisbursed;
      }
      if (_selectedFilter == 'PENDING') {
        return !item.isDisbursed;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(
        title: 'Refer & Earn',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(referralProvider.notifier).fetchDashboard();
        },
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(20),
          child: state.isLoading && dashboard.referralCode.isEmpty
              ? const SizedBox(
                  height: 400,
                  child: Center(
                    child: AppLoader(message: 'Loading your referral dashboard...'),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. HERO PUNCHLINE CARD
                    // ==========================================
                    _buildPunchlineCard(),

                    const SizedBox(height: 20),

                    // ==========================================
                    // 2. REFERRAL CODE & SHARE CARD
                    // ==========================================
                    _buildReferralCodeCard(dashboard),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. METRICS GRID (4 CARDS)
                    // ==========================================
                    _buildMetricsGrid(dashboard),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 4. HOW REFER & EARN WORKS
                    // ==========================================
                    _buildHowItWorksCard(),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 5. REFERRAL ACTIVITY LIST HEADER & FILTERS
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Referral Activity',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${dashboard.referralHistory.length} Total',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(null, 'All (${dashboard.referralHistory.length})'),
                          _buildFilterChip(
                            'DISBURSED',
                            'Disbursed (${dashboard.referralHistory.where((i) => i.isDisbursed).length})',
                          ),
                          _buildFilterChip(
                            'PENDING',
                            'Pending (${dashboard.referralHistory.where((i) => !i.isDisbursed).length})',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ==========================================
                    // 6. REFERRAL ACTIVITY LIST ITEMS
                    // ==========================================
                    if (historyItems.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: historyItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = historyItems[index];
                          return _buildActivityCard(item);
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ),
    );
  }

  /// Punchline Card: "Invite Peers, Slash Assessment & Processing Fees!"
  Widget _buildPunchlineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF0F5A47), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.discount_rounded,
                  color: Color(0xFF34D399),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEE WAIVER DISCOUNT',
                      style: TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Invite Peers, Slash Assessment & Processing Fees! 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Refer friends to Fin-Tree! Once their loan is disbursed, you unlock processing & assessment fee waiver discounts on your next loan application.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Referral Code Box with Copy & Native OS Share Sheet
  Widget _buildReferralCodeCard(ReferralDashboardModel dashboard) {
    final code = dashboard.referralCode.isNotEmpty ? dashboard.referralCode : 'FIN10025';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Unique Referral Code',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Code Row with 1-Tap Copy
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    color: Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(code),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryTeal),
                        SizedBox(width: 6),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Share Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _shareReferralLink(code, dashboard.shareLink),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text(
                'Share Link with Friends',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4 Metric Cards Grid
  Widget _buildMetricsGrid(ReferralDashboardModel dashboard) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Invites',
                value: '${dashboard.totalReferrals}',
                icon: Icons.people_alt_rounded,
                bgColor: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Disbursed Referrals',
                value: '${dashboard.successfulReferrals}',
                icon: Icons.task_alt_rounded,
                bgColor: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12, height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Active Discount Waiver',
                value: CurrencyUtils.formatAmount(dashboard.availableDiscount),
                icon: Icons.local_offer_rounded,
                bgColor: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                subtitle: dashboard.hasAvailableBenefit ? '${dashboard.availableBenefitsCount} Benefit Available' : 'No Active Benefit',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Savings Claimed',
                value: CurrencyUtils.formatAmount(dashboard.usedDiscount),
                icon: Icons.savings_rounded,
                bgColor: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// How Refer & Earn Works Card
  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How Refer & Earn Works',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepRow(
            '1',
            'Share Code or Link',
            'Send your referral code or direct link to peers via WhatsApp or SMS.',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SizedBox(height: 14, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
          ),
          _buildStepRow(
            '2',
            'Friend Loan Disbursed',
            'Your referred peer completes application and receives loan disbursal.',
          ),
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SizedBox(height: 14, child: VerticalDivider(color: Color(0xFFCBD5E1), thickness: 1.5)),
          ),
          _buildStepRow(
            '3',
            'Get Processing Fee Discount',
            'Your next loan application gets an automatic assessment & processing fee waiver discount!',
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String stepNum, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNum,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String? value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
        selectedColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() => _selectedFilter = value);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Referrals Yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Share your referral code with friends to start earning fee waiver discounts!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ReferralHistoryItem item) {
    final isDisbursed = item.isDisbursed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDisbursed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDisbursed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
              color: isDisbursed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Referred: ${_formatDate(item.referredAt)}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Loan Stage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDisbursed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.loanStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDisbursed ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Reward Status
              Text(
                item.formattedRewardStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: item.isBenefitCredited ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }
}
