import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/lender_offer_multiplier.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../journey_controller.dart';
import '../../../../core/providers/notifications_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../widgets/notification_center_modal.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab =
      0; // 0: Loan Overview / Post-approval, 1: Application / My Loans
  int _selectedNavIndex = 0;

  Future<void> _refreshDashboard() async {
    await ref.read(journeyControllerProvider.notifier).syncCustomerState();
  }

  Future<void> _logout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ref.watch(appLocalizationsProvider).tr('logout_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(appLocalizationsProvider).tr('logout_message'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          ref.watch(appLocalizationsProvider).tr('cancel'),
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          ref.watch(appLocalizationsProvider).tr('logout'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout != true) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _openRoute(String route) {
    if (route.trim().isEmpty) return;
    context.push(route);
  }

  String _readText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatStatus(String value) {
    return value
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) =>
            '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _getPrimaryButtonLabel(JourneyState state) {
    final route = state.targetRoute;
    if (route.contains('/offer'))
      return ref
          .watch(appLocalizationsProvider)
          .tr('review_approved_loan_offer');
    if (route.contains('/digilocker'))
      return ref.watch(appLocalizationsProvider).tr('complete_digilocker_kyc');
    if (route.contains('/address'))
      return ref
          .watch(appLocalizationsProvider)
          .tr('confirm_residence_address');
    if (route.contains('/bank'))
      return ref.watch(appLocalizationsProvider).tr('verify_bank_account');
    if (route.contains('/kfs'))
      return ref.watch(appLocalizationsProvider).tr('review_accept_kfs');
    if (route.contains('/mandate'))
      return ref.watch(appLocalizationsProvider).tr('register_enach_mandate');
    if (route.contains('/esign'))
      return ref.watch(appLocalizationsProvider).tr('complete_agreement_esign');
    if (route.contains('/disbursal'))
      return ref.watch(appLocalizationsProvider).tr('view_disbursal_status');
    if (route.contains('/application/status'))
      return ref.watch(appLocalizationsProvider).tr('check_application_status');
    if (route.contains('/onboarding'))
      return ref
          .watch(appLocalizationsProvider)
          .tr('continue_loan_application');
    return ref.watch(appLocalizationsProvider).tr('start_application');
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;
    final offer = postApproval?.offer;
    final bank = postApproval?.bank;
    final workflow = postApproval?.workflow;

    final customerName = _readText(customer?.fullName, 'Rohit Sharma');
    final applicationStatus =
        _readText(customer?.latestApplicationStatus, 'IN_PROGRESS');

    final disbursalStatus = _readText(workflow?.disbursalStatus, 'NOT_STARTED');
    final currentStep = _readText(workflow?.currentStep, 'APPROVAL_SUMMARY');
    final isDisbursed = currentStep == 'DISBURSED' ||
        disbursalStatus == 'DISBURSED' ||
        postApproval?.loan.disbursalCompletedAt != null ||
        customer?.latestLoanStatus == 'DISBURSED' ||
        customer?.latestLoanStatus == 'FULLY_PAID';

    final loanStatus =
        _readText(postApproval?.loan.status ?? customer?.latestLoanStatus, '')
            .toUpperCase();
    final isFullyPaid = loanStatus == 'FULLY_PAID' || loanStatus == 'CLOSED';

    final hasActiveLoan =
        (customer?.latestLan?.toString().isNotEmpty ?? false) &&
            (workflow?.offerAccepted == true ||
                customer?.latestApplicationStatus == 'LENDER_APPROVED');

    final tr = ref.watch(appLocalizationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F5A47),
          backgroundColor: Colors.white,
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top FinLeaf User Header ──────────────────────────────
                _buildHeader(customerName),
                const SizedBox(height: 20),

                // ── 2. Hero Goals Banner ────────────────────────────────────
                _buildHeroGoalsBanner(),
                const SizedBox(height: 22),

                // ── 3. Loan Overview KPI Stats Bar ──────────────────────────
                _buildLoanOverviewKPIs(
                  customer: customer,
                  hasActiveLoan: hasActiveLoan,
                  isDisbursed: isDisbursed,
                ),
                const SizedBox(height: 22),

                // ── 4. Dynamic Segment Switcher ─────────────────────────────
                if (hasActiveLoan) ...[
                  _buildSegmentedTabSelector(isDisbursed),
                  const SizedBox(height: 18),
                ],

                // ── 5. Main Content Switching Body ──────────────────────────
                if (!hasActiveLoan)
                  _buildApplicationTab(
                    journeyState: journeyState,
                    customer: customer,
                  )
                else if (_selectedTab == 0)
                  _buildPostApprovalTab(
                    journeyState: journeyState,
                    postApproval: postApproval,
                    offer: offer,
                    bank: bank,
                    workflow: workflow,
                  )
                else if (isDisbursed)
                  _buildMyLoansTab(
                    journeyState: journeyState,
                    customer: customer,
                    postApproval: postApproval,
                  )
                else
                  _buildApplicationTab(
                    journeyState: journeyState,
                    customer: customer,
                  ),

                const SizedBox(height: 24),

                // ── 6. Personal Loan Promotional Card ───────────────────────
                if (!isDisbursed || isFullyPaid) ...[
                  _buildPersonalLoanPromoCard(journeyState),
                  const SizedBox(height: 24),
                ],

                // ── 7. Smart Credit Perks & Readiness Hub ──────────────────
                _buildSmartCreditPerksHub(),
                //const SizedBox(height: 24),

                // ── 8. Refer & Earn Cashback Banner ─────────────────────────
                //_buildReferralDashboardCard(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, journeyState),
    );
  }

  // ── Header Widget ──────────────────────────────────────────────────────────
  Widget _buildHeader(String customerName) {
    final firstChar = customerName.trim().isNotEmpty
        ? customerName.trim()[0].toUpperCase()
        : 'R';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFF0F5A47),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              firstChar,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.watch(appLocalizationsProvider).tr('hello'),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        Consumer(
          builder: (context, ref, child) {
            final unreadCount = ref.watch(notificationsProvider).unreadCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => NotificationCenterModal.show(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 21,
                      ),
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: _logout,
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero Goals Banner ──────────────────────────────────────────────────────
  Widget _buildHeroGoalsBanner() {
    return Container(
      width: double.infinity,
      height: 142,
      decoration: BoxDecoration(
        color: const Color(0xFF0A4436),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A4436).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ref.watch(appLocalizationsProvider).tr('hero_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ref.watch(appLocalizationsProvider).tr('hero_subtitle'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              bottom: -4,
              child: SvgPicture.asset(
                'lib/assets/images/illustrations/Mobile Marketing-rafiki.svg',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loan Overview KPI Metric Bar ──────────────────────────────────────────
  Widget _buildLoanOverviewKPIs({
    required dynamic customer,
    required bool hasActiveLoan,
    required bool isDisbursed,
  }) {
    final applicationCount =
        (customer?.latestApplicationId != null) ? '1' : '0';
    final approvedCount = (hasActiveLoan ||
            customer?.latestApplicationStatus == 'LENDER_APPROVED')
        ? '1'
        : '0';
    final activeLoanCount = isDisbursed ? '1' : '0';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ref.watch(appLocalizationsProvider).tr('loan_overview'),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            InkWell(
              onTap: () => _openRoute('/application/status'),
              child: Row(
                children: [
                  Text(
                    ref.watch(appLocalizationsProvider).tr('view_all'),
                    style: const TextStyle(
                      color: Color(0xFF0F5A47),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF0F5A47),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _OverviewStatCard(
                count: applicationCount,
                label: ref.watch(appLocalizationsProvider).tr('application'),
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewStatCard(
                count: approvedCount,
                label: ref.watch(appLocalizationsProvider).tr('approved'),
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OverviewStatCard(
                count: activeLoanCount,
                label: ref.watch(appLocalizationsProvider).tr('active_loan'),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF3B82F6),
                bgColor: const Color(0xFFEFF6FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Segmented Control Switcher ─────────────────────────────────────────────
  Widget _buildSegmentedTabSelector(bool isDisbursed) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF0F5A47)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isDisbursed
                        ? ref
                            .watch(appLocalizationsProvider)
                            .tr('loan_overview')
                        : ref
                            .watch(appLocalizationsProvider)
                            .tr('loan_journey'),
                    style: TextStyle(
                      color: _selectedTab == 0
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF0F5A47)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isDisbursed
                        ? ref.watch(appLocalizationsProvider).tr('my_loans')
                        : ref
                            .watch(appLocalizationsProvider)
                            .tr('application_tab'),
                    style: TextStyle(
                      color: _selectedTab == 1
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Post-Approval Tab ─────────────────────────────────────────────────────
  Widget _buildPostApprovalTab({
    required JourneyState journeyState,
    required dynamic postApproval,
    required dynamic offer,
    required dynamic bank,
    required dynamic workflow,
  }) {
    final lan = _readText(postApproval?.loan?.lan, 'FFPL000001');
    final disbursalStatus = _readText(workflow?.disbursalStatus, 'NOT_STARTED');
    final currentStep = _readText(workflow?.currentStep, 'APPROVAL_SUMMARY');
    final isDisbursalProcessing = currentStep == 'DISBURSAL_PROCESSING' ||
        disbursalStatus == 'PROCESSING' ||
        disbursalStatus == 'INITIATED';
    final isDisbursed = currentStep == 'DISBURSED' ||
        disbursalStatus == 'DISBURSED' ||
        postApproval?.loan?.disbursalCompletedAt != null;

    if (isDisbursed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDisbursedCard(
            lan,
            postApproval: postApproval,
            customer: journeyState.customer,
          ),
          const SizedBox(height: 20),
          _buildMyLoansTab(
            journeyState: journeyState,
            customer: journeyState.customer,
            postApproval: postApproval,
          ),
        ],
      );
    }

    final num? rawApproved = postApproval?.loan?.approvedAmount ??
        postApproval?.loan?.disbursalAmount ??
        postApproval?.offer?.approvedAmount;
    final double? approvedAmount = (rawApproved != null && rawApproved > 0)
        ? rawApproved.toDouble()
        : null;
    final lenderName = _readText(
        postApproval?.lender?.name, 'Fintree Finance Private Limited');
    final acceptedTenure = offer?.acceptedTenureDays ?? 90;
    final acceptedEmi = offer?.acceptedEmiAmount;
    final bankName = _readText(bank?.bankName, 'Bank account');
    final accountMasked = _readText(bank?.accountMasked, '');

    final steps = <_JourneyStep>[
      _JourneyStep(
        number: 1,
        title: ref.watch(appLocalizationsProvider).tr('verify_bank_step'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('verify_bank_step_sub'),
        icon: Icons.account_balance_outlined,
        isCompleted: workflow?.bankVerified == true,
        route: '/loan/$lan/bank',
      ),
      _JourneyStep(
        number: 2,
        title: ref.watch(appLocalizationsProvider).tr('accept_kfs_step'),
        subtitle: ref.watch(appLocalizationsProvider).tr('accept_kfs_step_sub'),
        icon: Icons.fact_check_outlined,
        isCompleted: workflow?.kfsAccepted == true,
        route: '/loan/$lan/kfs',
      ),
      _JourneyStep(
        number: 3,
        title: ref.watch(appLocalizationsProvider).tr('register_mandate_step'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('register_mandate_step_sub'),
        icon: Icons.sync_alt_rounded,
        isCompleted: workflow?.mandateCompleted == true,
        route: '/loan/$lan/mandate',
      ),
      _JourneyStep(
        number: 4,
        title: ref.watch(appLocalizationsProvider).tr('esign_step'),
        subtitle: ref.watch(appLocalizationsProvider).tr('esign_step_sub'),
        icon: Icons.draw_outlined,
        isCompleted: workflow?.esignCompleted == true,
        route: '/loan/$lan/esign',
      ),
      _JourneyStep(
        number: 5,
        title: ref.watch(appLocalizationsProvider).tr('disbursal_step'),
        subtitle: ref.watch(appLocalizationsProvider).tr('disbursal_step_sub'),
        icon: Icons.currency_rupee_rounded,
        isCompleted: workflow?.readyForDisbursal == true,
        route: '/loan/$lan/disbursal',
      ),
    ];

    final completedCount = steps.where((step) => step.isCompleted).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Approved Loan Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF033F45),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF033F45).withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(appLocalizationsProvider).tr('approved_loan'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        approvedAmount != null
                            ? CurrencyUtils.formatAmount(approvedAmount)
                            : ref
                                .watch(appLocalizationsProvider)
                                .tr('pending_confirmation_label'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: approvedAmount != null ? 28 : 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lenderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LoanSummaryMetric(
                            icon: Icons.schedule_rounded,
                            label: ref
                                .watch(appLocalizationsProvider)
                                .tr('tenure'),
                            value: '$acceptedTenure days',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        Expanded(
                          child: _LoanSummaryMetric(
                            icon: Icons.payments_outlined,
                            label: ref
                                .watch(appLocalizationsProvider)
                                .tr('monthly_emi'),
                            value: acceptedEmi == null
                                ? ref
                                    .watch(appLocalizationsProvider)
                                    .tr('to_be_confirmed')
                                : CurrencyUtils.formatAmount(acceptedEmi,
                                    showDecimals: true),
                          ),
                        ),
                      ],
                    ),
                    if (accountMasked.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$bankName • $accountMasked',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LAN: $lan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(currentStep),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (isDisbursed)
          _buildDisbursedCard(lan)
        else if (isDisbursalProcessing)
          _buildCreditingSoonCard(lan)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF0F5A47),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('your_next_step'),
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('complete_step_disbursal'),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: _getPrimaryButtonLabel(journeyState),
                  onPressed: () => _openRoute(journeyState.targetRoute),
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),

        if (!isDisbursed) ...[
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.watch(appLocalizationsProvider).tr(
                    'loan_journey_progress', {
                  'completed': '$completedCount',
                  'total': '${steps.length}'
                }),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF0F5A47),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF0F5A47)),
            ),
          ),
          const SizedBox(height: 14),
          ...steps
              .sublist(0, (completedCount + 1).clamp(0, steps.length))
              .asMap()
              .entries
              .map(
            (entry) {
              final step = entry.value;
              final isCurrent = journeyState.targetRoute == step.route;
              return _JourneyStepTile(
                step: step,
                isCurrent: isCurrent,
                isLast: entry.key ==
                    (completedCount + 1).clamp(0, steps.length) - 1,
                onTap: () => _openRoute(step.route),
              );
            },
          ),
        ],
      ],
    );
  }

  // ── Crediting & Disbursed Status Cards ────────────────────────────────────
  Widget _buildCreditingSoonCard(String lan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFD97706),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your loan will be credited shortly!',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        fontSize: 14.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Disbursal is being processed by the lender.',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            text: ref.watch(appLocalizationsProvider).tr('view_loan_details'),
            onPressed: () => _openRoute('/loan/$lan/loan-details'),
            icon: Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildDisbursedCard(
    String lan, {
    dynamic postApproval,
    dynamic customer,
  }) {
    final loan = postApproval?.loan;
    final offer = postApproval?.offer;
    final lender = postApproval?.lender;
    final bank = postApproval?.bank;

    final num? rawApproved =
        loan?.approvedAmount ?? loan?.disbursalAmount ?? offer?.approvedAmount;
    final double? approvedAmount = (rawApproved != null && rawApproved > 0)
        ? rawApproved.toDouble()
        : null;
    final emiAmount = offer?.acceptedEmiAmount;
    final lenderName = _readText(lender?.name,
        customer?.allocatedLenderName ?? 'Fintree Finance Private Limited');
    final utr = _readText(loan?.disbursalUtr, 'N/A');
    final bankName = _readText(bank?.bankName, 'Bank account');
    final accountMasked = _readText(bank?.accountMasked, '');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0A4436),
              borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref
                            .watch(appLocalizationsProvider)
                            .tr('active_disbursed_loan'),
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ref
                            .watch(appLocalizationsProvider)
                            .tr('funds_credited_bank'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ref.watch(appLocalizationsProvider).tr('disbursed'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref
                              .watch(appLocalizationsProvider)
                              .tr('disbursed_amount'),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          approvedAmount != null
                              ? CurrencyUtils.formatAmount(approvedAmount)
                              : ref
                                  .watch(appLocalizationsProvider)
                                  .tr('pending_confirmation_label'),
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: approvedAmount != null ? 26 : 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (emiAmount != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('monthly_emi'),
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyUtils.formatAmount(emiAmount),
                            style: const TextStyle(
                              color: Color(0xFF0F5A47),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('loan_account_lan'),
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 11.5),
                          ),
                          Text(
                            lan.isNotEmpty ? lan : 'N/A',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ref.watch(appLocalizationsProvider).tr('lender'),
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 11.5),
                          ),
                          Text(
                            lenderName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (utr != 'N/A') ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ref
                                  .watch(appLocalizationsProvider)
                                  .tr('disbursal_utr'),
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11.5),
                            ),
                            Text(
                              utr,
                              style: const TextStyle(
                                color: Color(0xFF059669),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (accountMasked.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ref
                                  .watch(appLocalizationsProvider)
                                  .tr('credited_account'),
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11.5),
                            ),
                            Text(
                              '$bankName • $accountMasked',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: ref
                      .watch(appLocalizationsProvider)
                      .tr('pay_emi_repay_loan'),
                  onPressed: () => _openRoute('/loan/$lan/repay'),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: ref
                      .watch(appLocalizationsProvider)
                      .tr('view_full_loan_details_rps'),
                  isOutlined: true,
                  onPressed: () => _openRoute('/loan/$lan/loan-details'),
                  icon: Icons.receipt_long_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── My Loans Tab ──────────────────────────────────────────────────────────
  Widget _buildMyLoansTab({
    required JourneyState journeyState,
    required dynamic customer,
    required dynamic postApproval,
  }) {
    final loan = postApproval?.loan;
    final offer = postApproval?.offer;
    final bank = postApproval?.bank;
    final lender = postApproval?.lender;

    final lan = _readText(loan?.lan ?? customer?.latestLan, '');
    final status =
        _readText(loan?.status ?? customer?.latestLoanStatus, 'DISBURSED')
            .toUpperCase();
    final num? rawApproved =
        loan?.approvedAmount ?? loan?.disbursalAmount ?? offer?.approvedAmount;
    final double? approvedAmount = (rawApproved != null && rawApproved > 0)
        ? rawApproved.toDouble()
        : null;
    final lenderName =
        _readText(lender?.name, 'Fintree Finance Private Limited');
    final utr = _readText(loan?.disbursalUtr, 'N/A');
    final isFullyPaid = status == 'FULLY_PAID' || status == 'CLOSED';

    final int completedLoansCount = (customer?.completedLoansCount ?? 0) > 0
        ? customer!.completedLoansCount
        : 1;
    final double offerMultiplier =
        LenderMultiplierCalculator.getMultiplier(completedLoansCount);
    final double revisedLoanLimit =
        LenderMultiplierCalculator.calculateRevisedLimit(
            approvedAmount ?? 0, completedLoansCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFullyPaid) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        color: Colors.amber, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pre-Approved Repeat Loan (${offerMultiplier}x applied)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Eligible for revised limit of ${CurrencyUtils.formatAmount(revisedLoanLimit)} with instant disbursal.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => _openRoute('/onboarding/basic-details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF065F46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                      ref
                          .watch(appLocalizationsProvider)
                          .tr('apply_repeat_loan'),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Loan Card
        InkWell(
          onTap: () => _openRoute('/loan/$lan/loan-details'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0F5A47),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lan,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              lenderName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppStatusBadge(
                      status: isFullyPaid ? 'FULLY_PAID' : 'DISBURSED',
                      label: isFullyPaid
                          ? ref.watch(appLocalizationsProvider).tr('fully_paid')
                          : ref.watch(appLocalizationsProvider).tr('disbursed'),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref
                              .watch(appLocalizationsProvider)
                              .tr('approved_loan_amount_label'),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          approvedAmount != null
                              ? CurrencyUtils.formatAmount(approvedAmount)
                              : ref
                                  .watch(appLocalizationsProvider)
                                  .tr('pending_confirmation_label'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F5A47),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ref
                              .watch(appLocalizationsProvider)
                              .tr('destination_bank_label'),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bank?.bankName ?? 'Bank Account',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UTR: $utr',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('view_rps_label'),
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F5A47)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: Color(0xFF0F5A47)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Application Tab ───────────────────────────────────────────────────────
  Widget _buildApplicationTab({
    required JourneyState journeyState,
    required dynamic customer,
  }) {
    final applicationStatus =
        _readText(customer?.latestApplicationStatus, 'IN_PROGRESS');
    final fullName = _readText(customer?.fullName, 'Not provided');
    final email = _readText(customer?.email, 'Not provided');
    final panNumber = _readText(customer?.panNumber, 'Not provided');
    final employmentType = _readText(customer?.employmentType, 'Not provided');
    final employerName = _readText(
        customer?.companyName ?? customer?.businessName, 'Not provided');
    final residentialPincode =
        _readText(customer?.residentialPincode, 'Not provided');
    final monthlyIncome = customer?.monthlyIncome;

    final panVerified = customer?.panVerified == true;
    final mobileVerified = customer?.mobileVerified == true;
    final emailVerified = customer?.emailVerified == true;

    final statusUpper = applicationStatus.toUpperCase();
    final applicationSubmitted = statusUpper.contains('SUBMITTED') ||
        statusUpper.contains('APPROVED') ||
        statusUpper.contains('SANCTION') ||
        statusUpper.contains('DISBURS');

    final basicDetailsComplete =
        fullName != 'Not provided' && emailVerified == true;
    final profileComplete =
        employmentType != 'Not provided' || monthlyIncome != null;
    final assessmentFeePaid = customer?.assessmentFeePaid == true;
    final postApproval = journeyState.postApproval;
    final offerAccepted = postApproval?.workflow.offerAccepted == true;

    final livenessComplete = customer != null &&
        !customer.updateReadinessReasons.contains('LIVENESS_NOT_VERIFIED');
    final digilockerComplete = customer != null &&
        (customer.aadhaarVerified == true ||
            customer.aadhaarKycStatus == 'VERIFIED');
    final addressComplete = customer != null &&
        !customer.updateReadinessReasons.contains('ADDRESS_NOT_VERIFIED') &&
        !customer.updateReadinessReasons
            .contains('RESIDENTIAL_ADDRESS_NOT_VERIFIED') &&
        (customer.residentialCity != null &&
            customer.residentialCity != 'Not provided');
    final aaComplete = customer != null &&
        (customer.aaVerified == true ||
            ['SUCCESS', 'COMPLETED', 'VERIFIED']
                .contains(customer.aaStatus?.toUpperCase()) ||
            ['SUCCESS', 'COMPLETED', 'VERIFIED']
                .contains(customer.accountAggregatorStatus?.toUpperCase()));

    final applicationSteps = <_ApplicationStep>[
      _ApplicationStep(
        number: 1,
        title: ref.watch(appLocalizationsProvider).tr('step_basic_details'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('step_basic_details_sub'),
        icon: Icons.person_outline_rounded,
        route: '/onboarding/basic-details',
        isCompleted: applicationSubmitted || basicDetailsComplete,
      ),
      _ApplicationStep(
        number: 2,
        title: ref.watch(appLocalizationsProvider).tr('step_pan_verification'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('step_pan_verification_sub'),
        icon: Icons.badge_outlined,
        route: '/onboarding/pan',
        isCompleted: applicationSubmitted || panVerified,
      ),
      _ApplicationStep(
        number: 3,
        title: ref.watch(appLocalizationsProvider).tr('step_lender_assessment'),
        subtitle: ref
            .watch(appLocalizationsProvider)
            .tr('step_lender_assessment_sub'),
        icon: Icons.payment_rounded,
        route: '/payment/processing-fee',
        isCompleted: applicationSubmitted || assessmentFeePaid,
      ),
      _ApplicationStep(
        number: 4,
        title: ref.watch(appLocalizationsProvider).tr('step_profile_income'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('step_profile_income_sub'),
        icon: Icons.work_outline_rounded,
        route: '/onboarding/profile',
        isCompleted: applicationSubmitted || profileComplete,
      ),
      _ApplicationStep(
        number: 5,
        title: ref.watch(appLocalizationsProvider).tr('step_live_photo'),
        subtitle: ref.watch(appLocalizationsProvider).tr('step_live_photo_sub'),
        icon: Icons.face_retouching_natural_outlined,
        route: '/onboarding/live-photo',
        isCompleted: applicationSubmitted || livenessComplete,
      ),
      _ApplicationStep(
        number: 6,
        title: ref.watch(appLocalizationsProvider).tr('step_digilocker'),
        subtitle: ref.watch(appLocalizationsProvider).tr('step_digilocker_sub'),
        icon: Icons.verified_user_outlined,
        route: '/onboarding/digilocker',
        isCompleted: applicationSubmitted || digilockerComplete,
      ),
      _ApplicationStep(
        number: 7,
        title: ref.watch(appLocalizationsProvider).tr('step_address'),
        subtitle: ref.watch(appLocalizationsProvider).tr('step_address_sub'),
        icon: Icons.home_outlined,
        route: '/onboarding/address',
        isCompleted: applicationSubmitted || addressComplete,
      ),
      _ApplicationStep(
        number: 8,
        title: ref.watch(appLocalizationsProvider).tr('step_aa'),
        subtitle: ref.watch(appLocalizationsProvider).tr('step_aa_sub'),
        icon: Icons.account_balance_outlined,
        route: '/onboarding/account-aggregator',
        isCompleted: applicationSubmitted || aaComplete,
      ),
      _ApplicationStep(
        number: 9,
        title: ref.watch(appLocalizationsProvider).tr('step_loan_offer'),
        subtitle: ref.watch(appLocalizationsProvider).tr('step_loan_offer_sub'),
        icon: Icons.local_offer_outlined,
        route: '/onboarding/offer',
        isCompleted: applicationSubmitted || offerAccepted,
      ),
      _ApplicationStep(
        number: 10,
        title: ref.watch(appLocalizationsProvider).tr('step_review_submit'),
        subtitle:
            ref.watch(appLocalizationsProvider).tr('step_review_submit_sub'),
        icon: Icons.task_alt_rounded,
        route: '/onboarding/review',
        isCompleted: applicationSubmitted,
      ),
    ];

    final completedSteps =
        applicationSteps.where((step) => step.isCompleted).length;
    final applicationProgress = applicationSteps.isEmpty
        ? 0.0
        : completedSteps / applicationSteps.length;

    String? nextIncompleteRoute;
    for (final step in applicationSteps) {
      if (!step.isCompleted) {
        nextIncompleteRoute = step.route;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'lib/assets/images/illustrations/Filing system-rafiki.svg',
                          height: 48,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref
                                    .watch(appLocalizationsProvider)
                                    .tr('application_dossier'),
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref
                                    .watch(appLocalizationsProvider)
                                    .tr('personal_loan_fintree'),
                                style: const TextStyle(
                                    color: Color(0xFF64748B), fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusBadge(status: applicationStatus),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _VerificationStatusCard(
                      label: 'Mobile',
                      isVerified: mobileVerified,
                      icon: Icons.phone_android_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VerificationStatusCard(
                      label: 'PAN',
                      isVerified: panVerified,
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VerificationStatusCard(
                      label: 'Email',
                      isVerified: emailVerified,
                      icon: Icons.email_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: applicationProgress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF0F5A47)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ref.watch(appLocalizationsProvider).tr('steps_completed', {
                      'completed': '$completedSteps',
                      'total': '${applicationSteps.length}'
                    }),
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                  Text(
                    '${(applicationProgress * 100).round()}%',
                    style: const TextStyle(
                      color: Color(0xFF0F5A47),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (applicationSubmitted)
                AppButton(
                  text: ref
                      .watch(appLocalizationsProvider)
                      .tr('view_application_status'),
                  isOutlined: true,
                  onPressed: () => _openRoute('/application/status'),
                  icon: Icons.analytics_outlined,
                )
              else if (nextIncompleteRoute != null)
                AppButton(
                  text: (nextIncompleteRoute == '/onboarding/basic-details' ||
                          emailVerified != true)
                      ? ref.watch(appLocalizationsProvider).tr('apply_for_loan')
                      : ref
                          .watch(appLocalizationsProvider)
                          .tr('resume_application'),
                  onPressed: () async {
                    await ref
                        .read(journeyControllerProvider.notifier)
                        .syncCustomerState();
                    if (mounted) {
                      final target =
                          ref.read(journeyControllerProvider).targetRoute;
                      _openRoute((target.isNotEmpty &&
                              target != '/dashboard' &&
                              target != '/login')
                          ? target
                          : nextIncompleteRoute!);
                    }
                  },
                  icon: Icons.arrow_forward_rounded,
                )
              else
                AppButton(
                  text: ref
                      .watch(appLocalizationsProvider)
                      .tr('review_submit_application'),
                  onPressed: () => _openRoute('/onboarding/review'),
                  icon: Icons.arrow_forward_rounded,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Applicant Profile Details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ref.watch(appLocalizationsProvider).tr('applicant_profile'),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _ProfileDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Applicant Name',
                  value: fullName),
              _ProfileDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: email),
              _ProfileDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'PAN Number',
                  value: panNumber),
              _ProfileDetailRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Employment Type',
                  value: employmentType),
              _ProfileDetailRow(
                  icon: Icons.business_outlined,
                  label: 'Employer / Business',
                  value: employerName),
              _ProfileDetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Monthly Net Income',
                value: monthlyIncome == null
                    ? 'Not provided'
                    : CurrencyUtils.formatAmount(monthlyIncome),
              ),
              _ProfileDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Residence Pincode',
                value: residentialPincode,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          ref.watch(appLocalizationsProvider).tr('application_journey'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...applicationSteps
            .sublist(0, (completedSteps + 1).clamp(0, applicationSteps.length))
            .map(
          (step) {
            final isCurrent = journeyState.targetRoute == step.route;
            return _ApplicationStepTile(
              step: step,
              isCurrent: isCurrent,
              onTap: () => _openRoute(step.route),
            );
          },
        ),
      ],
    );
  }

  // ── Promo Card: Need Personal Loan ────────────────────────────────────────
  Widget _buildPersonalLoanPromoCard(JourneyState journeyState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEDE4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(appLocalizationsProvider).tr('need_personal_loan'),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.watch(appLocalizationsProvider).tr('get_instant_offers'),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    final target = journeyState.targetRoute;
                    _openRoute(
                      (target.isNotEmpty &&
                              target != '/dashboard' &&
                              target != '/login')
                          ? target
                          : '/onboarding/basic-details',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5A47),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ref.watch(appLocalizationsProvider).tr('apply_now'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'lib/assets/images/illustrations/Completed-pana.svg',
            height: 75,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  // ── Smart Credit Perks & Readiness Hub ────────────────────────────────────
  Widget _buildSmartCreditPerksHub() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F5A47).withValues(alpha: 0.05),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref
                          .watch(appLocalizationsProvider)
                          .tr('smart_credit_benefits'),
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ref.watch(appLocalizationsProvider).tr('exclusive_perks'),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Color(0xFF059669),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      ref.watch(appLocalizationsProvider).tr('high_odds'),
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A4436), Color(0xFF0F5A47)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded,
                              color: Color(0xFF34D399), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('approval_readiness'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.88,
                          minHeight: 6,
                          backgroundColor: Color(0xFF063328),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ref
                            .watch(appLocalizationsProvider)
                            .tr('pre_verified_instant'),
                        style: const TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SvgPicture.asset(
                  'lib/assets/images/illustrations/Personal settings-cuate.svg',
                  height: 65,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerkCard(
                  icon: Icons.bolt_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: ref
                      .watch(appLocalizationsProvider)
                      .tr('instant_disbursal'),
                  subtitle: ref
                      .watch(appLocalizationsProvider)
                      .tr('direct_transfer_esign'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPerkCard(
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: ref
                      .watch(appLocalizationsProvider)
                      .tr('zero_foreclosure'),
                  subtitle:
                      ref.watch(appLocalizationsProvider).tr('pay_off_anytime'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPerkCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title:
                      ref.watch(appLocalizationsProvider).tr('tier_multiplier'),
                  subtitle: ref
                      .watch(appLocalizationsProvider)
                      .tr('higher_limits_emi'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPerkCard(
                  icon: Icons.document_scanner_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: ref.watch(appLocalizationsProvider).tr('digital_kyc'),
                  subtitle: ref
                      .watch(appLocalizationsProvider)
                      .tr('paperless_digilocker'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _showHelpSupportModal(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.headset_mic_rounded,
                        color: Color(0xFF0F5A47),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        ref
                            .watch(appLocalizationsProvider)
                            .tr('questions_credit_perks'),
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        ref.watch(appLocalizationsProvider).tr('support_label'),
                        style: const TextStyle(
                          color: Color(0xFF0F5A47),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF0F5A47),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomNavigationBar(
      BuildContext context, JourneyState journeyState) {
    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;
    final tr = ref.watch(appLocalizationsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.home_filled,
                label: tr.tr('home'),
                onTap: () => setState(() => _selectedNavIndex = 0),
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.assignment_outlined,
                label: tr.tr('application'),
                onTap: () {
                  setState(() => _selectedNavIndex = 1);
                  _openRoute('/application/status');
                },
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.account_balance_wallet_outlined,
                label: tr.tr('loan_details_nav'),
                onTap: () {
                  setState(() => _selectedNavIndex = 2);
                  final effectiveLan = customer?.latestLan ??
                      customer?.platformLan ??
                      postApproval?.loan.lan ??
                      '';
                  if (effectiveLan.isNotEmpty) {
                    if (customer?.latestLoanStatus == 'FULLY_PAID' ||
                        customer?.latestLoanStatus == 'CLOSED') {
                      _openRoute('/loan/$effectiveLan/fully-paid-review');
                    } else {
                      _openRoute('/loan/$effectiveLan/loan-details');
                    }
                  } else if ((customer?.latestApplicationId ?? '').isNotEmpty) {
                    _openRoute(
                        '/loan/${customer!.latestApplicationId}/loan-details');
                  } else {
                    _openRoute('/onboarding/offer');
                  }
                },
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                label: tr.tr('profile'),
                onTap: () {
                  setState(() => _selectedNavIndex = 3);
                  _showCustomerProfileModal(context, journeyState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedNavIndex == index;
    final color =
        isSelected ? const Color(0xFF0F5A47) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Modals: Profile & Support ──────────────────────────────────────────────
  void _showCustomerProfileModal(
      BuildContext context, JourneyState journeyState) {
    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;
    final bank = postApproval?.bank;

    final fullName = _readText(customer?.fullName, 'Rohit Sharma');
    final mobile = _readText(customer?.mobileNumber, '+91 98XXXX4321');
    final email = _readText(customer?.email, 'rohit@gmail.com');
    final pan = _readText(customer?.panNumber, 'ABCDE1234F');
    final employmentType = _readText(customer?.employmentType, 'Salaried');
    final employerName = _readText(
        customer?.companyName ?? customer?.businessName, 'Private Enterprise');
    final designation = _readText(customer?.designation, 'Senior Associate');
    final residenceStatus = _readText(customer?.residenceStatus, 'Owned');
    final pincode = _readText(customer?.residentialPincode, '401303');
    final monthlyIncome = customer?.monthlyIncome;
    final formattedIncome = (monthlyIncome != null && monthlyIncome > 0)
        ? CurrencyUtils.formatAmount(monthlyIncome)
        : 'Verified Profile';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.86,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header Hero Banner with SVG
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF073B2E),
                    Color(0xFF0F5A47),
                    Color(0xFF136E57),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 16, 20),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF34D399),
                                      width: 2.5),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669)
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399)
                                            .withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: const Color(0xFF34D399),
                                            width: 0.8),
                                      ),
                                      child: Text(
                                        ref
                                            .watch(appLocalizationsProvider)
                                            .tr('verified_badge'),
                                        style: const TextStyle(
                                          color: Color(0xFF6EE7B7),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  mobile,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'lib/assets/images/illustrations/Personal settings-cuate.svg',
                            height: 70,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Scrollable Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  // Verification Quick Stats Bar
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileMiniStat(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('profile_score'),
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('profile_verified'),
                            Icons.verified_user_rounded,
                            const Color(0xFF10B981)),
                        Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFFE2E8F0)),
                        _buildProfileMiniStat(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('kyc_status_label'),
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('digilocker_ok'),
                            Icons.badge_rounded,
                            const Color(0xFF0F5A47)),
                        Container(
                            width: 1,
                            height: 32,
                            color: const Color(0xFFE2E8F0)),
                        _buildProfileMiniStat(
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('lender_tier'),
                            ref
                                .watch(appLocalizationsProvider)
                                .tr('prime_match'),
                            Icons.workspace_premium_rounded,
                            const Color(0xFFD97706)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Identity & KYC Details
                  _buildProfileSectionCard(
                    title: ref
                        .watch(appLocalizationsProvider)
                        .tr('identity_kyc_details'),
                    icon: Icons.shield_rounded,
                    children: [
                      _ProfileDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Full Name',
                          value: fullName),
                      _ProfileDetailRow(
                          icon: Icons.phone_iphone_rounded,
                          label: 'Mobile Number',
                          value: mobile),
                      _ProfileDetailRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'Email Address',
                          value: email),
                      _ProfileDetailRow(
                          icon: Icons.subtitles_rounded,
                          label: 'PAN Card Number',
                          value: pan,
                          trailingBadge: 'VERIFIED'),
                      const _ProfileDetailRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'Aadhaar KYC',
                          value: 'DigiLocker Linked',
                          isVerified: true,
                          showDivider: false),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Employment & Financials
                  _buildProfileSectionCard(
                    title: ref
                        .watch(appLocalizationsProvider)
                        .tr('employment_financials'),
                    icon: Icons.work_rounded,
                    children: [
                      _ProfileDetailRow(
                          icon: Icons.business_center_rounded,
                          label: 'Employment Type',
                          value: employmentType),
                      _ProfileDetailRow(
                          icon: Icons.apartment_rounded,
                          label: 'Employer / Business',
                          value: employerName),
                      _ProfileDetailRow(
                          icon: Icons.badge_rounded,
                          label: 'Designation',
                          value: designation),
                      _ProfileDetailRow(
                        icon: Icons.payments_rounded,
                        label: 'Monthly Income',
                        value: formattedIncome,
                        highlight: true,
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Residence & Disbursal Account
                  _buildProfileSectionCard(
                    title: ref
                        .watch(appLocalizationsProvider)
                        .tr('residence_bank_details'),
                    icon: Icons.location_city_rounded,
                    children: [
                      _ProfileDetailRow(
                          icon: Icons.home_rounded,
                          label: 'Residence Status',
                          value: residenceStatus),
                      _ProfileDetailRow(
                          icon: Icons.map_rounded,
                          label: 'Residential Pincode',
                          value: pincode),
                      _ProfileDetailRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Disbursal Bank',
                        value: bank?.bankName ?? 'Primary Account',
                      ),
                      _ProfileDetailRow(
                        icon: Icons.credit_card_rounded,
                        label: 'Account Number',
                        value: bank?.accountMasked != null
                            ? 'XXXX XXXX ${bank!.accountMasked}'
                            : 'Linked Account',
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Section 4: Multi-Language Switcher (English & Hindi)
                  Consumer(
                    builder: (context, ref, child) {
                      final currentLang = ref.watch(localeProvider);
                      final notifier = ref.read(localeProvider.notifier);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F5A47)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.language_rounded,
                                      size: 18, color: Color(0xFF0F5A47)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  currentLang == 'hi'
                                      ? 'ऐप की भाषा (App Language)'
                                      : 'App Language',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => notifier.setLanguage('en'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: currentLang == 'en'
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: currentLang == 'en'
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('🇬🇧 ',
                                              style: TextStyle(fontSize: 16)),
                                          Text(
                                            'English',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: currentLang == 'en'
                                                  ? Colors.white
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                          if (currentLang == 'en') ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: Color(0xFF34D399)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => notifier.setLanguage('hi'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: currentLang == 'hi'
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: currentLang == 'hi'
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('🇮🇳 ',
                                              style: TextStyle(fontSize: 16)),
                                          Text(
                                            'हिंदी (Hindi)',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: currentLang == 'hi'
                                                  ? Colors.white
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                          if (currentLang == 'hi') ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                                Icons.check_circle_rounded,
                                                size: 14,
                                                color: Color(0xFF34D399)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Refer & Earn Banner Card in Profile Sheet
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF0F5A47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Color(0xFF34D399),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref
                                    .watch(appLocalizationsProvider)
                                    .tr('refer_earn'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref
                                    .watch(appLocalizationsProvider)
                                    .tr('refer_earn_sub'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push('/referral');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            ref.watch(appLocalizationsProvider).tr('invite'),
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Out Action Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    label: Text(
                      ref.watch(appLocalizationsProvider).tr('sign_out'),
                      style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _logout();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5A47), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFF34D399),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.watch(appLocalizationsProvider).tr('refer_earn'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ref.watch(appLocalizationsProvider).tr('refer_earn_sub'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => context.push('/referral'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              ref.watch(appLocalizationsProvider).tr('invite'),
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMiniStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildProfileSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5A47).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F5A47), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.62,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.headset_mic_rounded,
                        color: Color(0xFF0F5A47), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      ref.watch(appLocalizationsProvider).tr('help_support'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0xFFF1F5F9)),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF0F5A47)),
              title: const Text('FAQs',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Get answers to common questions',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone_in_talk_outlined,
                  color: Color(0xFF0F5A47)),
              title: const Text('Call Support',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('+91 1800 123 4567 (Mon - Sat)',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded,
                  color: Color(0xFF0F5A47)),
              title: const Text('Email Support',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('support@finleaf.in',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Helper Sub-widgets ────────────────────────────────────────────────

class _OverviewStatCard extends StatelessWidget {
  final String count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _OverviewStatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanSummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LoanSummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.68), size: 14),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailingBadge;
  final bool isVerified;
  final bool highlight;
  final bool showDivider;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingBadge,
    this.isVerified = false,
    this.highlight = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: highlight
                      ? const Color(0xFF0F5A47)
                      : const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                ),
              ),
              if (trailingBadge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              if (isVerified) ...[
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  color: highlight
                      ? const Color(0xFF0F5A47)
                      : const Color(0xFF0F172A),
                  fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
                  fontSize: highlight ? 14 : 12.5,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  final String label;
  final bool isVerified;
  final IconData icon;

  const _VerificationStatusCard({
    required this.label,
    required this.isVerified,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final background =
        isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final String route;

  const _JourneyStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.route,
  });
}

class _JourneyStepTile extends StatelessWidget {
  final _JourneyStep step;
  final bool isCurrent;
  final bool isLast;
  final VoidCallback onTap;

  const _JourneyStepTile({
    required this.step,
    required this.isCurrent,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = step.isCompleted
        ? const Color(0xFF10B981)
        : isCurrent
            ? const Color(0xFF0F5A47)
            : const Color(0xFF94A3B8);

    final statusBackground = step.isCompleted
        ? const Color(0xFFECFDF5)
        : isCurrent
            ? const Color(0xFFE6F4EA)
            : const Color(0xFFF1F5F9);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: step.isCompleted
                      ? Icon(Icons.check_rounded, color: statusColor, size: 16)
                      : Text(
                          '${step.number}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFF0F5A47)
                            : const Color(0xFFE2E8F0),
                        width: isCurrent ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(step.icon, color: statusColor, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isCompleted;

  const _ApplicationStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.isCompleted,
  });
}

class _ApplicationStepTile extends StatelessWidget {
  final _ApplicationStep step;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ApplicationStepTile({
    required this.step,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.isCompleted
        ? const Color(0xFF10B981)
        : isCurrent
            ? const Color(0xFF0F5A47)
            : const Color(0xFF94A3B8);

    final background = step.isCompleted
        ? const Color(0xFFECFDF5)
        : isCurrent
            ? const Color(0xFFE6F4EA)
            : const Color(0xFFF8FAFC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF0F5A47)
                    : const Color(0xFFE2E8F0),
                width: isCurrent ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(step.icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  step.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
