import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../journey_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0;

  Future<void> _refreshDashboard() async {
    await ref
        .read(journeyControllerProvider.notifier)
        .syncCustomerState();
  }

  Future<void> _logout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            22,
            14,
            22,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
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
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.errorRed,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout from your account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textDarkPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You will need to verify your mobile number again to access your loan journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textDarkSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.errorRed,
                        ),
                        child: const Text('Logout'),
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

  @override
  Widget build(BuildContext context) {
    final journeyState =
        ref.watch(journeyControllerProvider);

    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;
    final offer = postApproval?.offer;
    final bank = postApproval?.bank;
    final workflow = postApproval?.workflow;

    final customerName =
        _readText(customer?.fullName, 'Valued Customer');

    final mobileNumber =
        _readText(customer?.mobileNumber, 'Not available');

    final applicationStatus = _readText(
      customer?.latestApplicationStatus,
      'IN_PROGRESS',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F8),
      body: RefreshIndicator(
        color: AppTheme.primaryTeal,
        backgroundColor: Colors.white,
        onRefresh: _refreshDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                customerName: customerName,
                mobileNumber: mobileNumber,
                applicationStatus: applicationStatus,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                18,
                0,
                18,
                32,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: _buildDashboardBody(
                        journeyState: journeyState,
                        customer: customer,
                        postApproval: postApproval,
                        offer: offer,
                        bank: bank,
                        workflow: workflow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String customerName,
    required String mobileNumber,
    required String applicationStatus,
  }) {
    final firstLetter = customerName.trim().isNotEmpty
        ? customerName.trim()[0].toUpperCase()
        : 'C';

    return Container(
      height: 285,
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(38),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -65,
            right: -55,
            child: _BackgroundCircle(
              size: 190,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Positioned(
            top: 135,
            left: -70,
            child: _BackgroundCircle(
              size: 160,
              color: Colors.white.withOpacity(0.055),
            ),
          ),
          Positioned(
            top: 90,
            right: 70,
            child: _BackgroundCircle(
              size: 32,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                48,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        height: 48,
                        constraints: const BoxConstraints(
                          minWidth: 54,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.13),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'lib/assets/images/Logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.account_balance_rounded,
                              color: AppTheme.primaryTeal,
                              size: 28,
                            );
                          },
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _refreshDashboard,
                          borderRadius:
                              BorderRadius.circular(14),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: _logout,
                          borderRadius:
                              BorderRadius.circular(14),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.16),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color:
                                    Colors.white.withOpacity(0.76),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_android_rounded,
                                  color:
                                      Colors.white.withOpacity(0.7),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    mobileNumber,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.76),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.13),
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color:
                                Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _shortStatus(applicationStatus),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildDashboardBody({
    required JourneyState journeyState,
    required dynamic customer,
    required dynamic postApproval,
    required dynamic offer,
    required dynamic bank,
    required dynamic workflow,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF033F45)
                    .withOpacity(0.10),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _DashboardTabButton(
                  title: 'Loan Journey',
                  subtitle: 'Post-approval',
                  icon: Icons.account_balance_wallet_outlined,
                  isSelected: _selectedTab == 0,
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _DashboardTabButton(
                  title: 'Application',
                  subtitle: 'Profile & KYC',
                  icon: Icons.description_outlined,
                  isSelected: _selectedTab == 1,
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: _selectedTab == 0
              ? KeyedSubtree(
                  key: const ValueKey('post-approval'),
                  child: _buildPostApprovalTab(
                    journeyState: journeyState,
                    postApproval: postApproval,
                    offer: offer,
                    bank: bank,
                    workflow: workflow,
                  ),
                )
              : KeyedSubtree(
                  key: const ValueKey('application'),
                  child: _buildApplicationTab(
                    journeyState: journeyState,
                    customer: customer,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPostApprovalTab({
    required JourneyState journeyState,
    required dynamic postApproval,
    required dynamic offer,
    required dynamic bank,
    required dynamic workflow,
  }) {
    final lan = _readText(
      postApproval?.loan?.lan,
      'FFPL000001',
    );

    final approvedAmount =
        postApproval?.loan?.approvedAmount ?? 500000;

    final lenderName = _readText(
      postApproval?.lender?.name,
      'Fintree Finance Private Limited',
    );

    final currentStep = _readText(
      workflow?.currentStep,
      'APPROVAL_SUMMARY',
    );

    final acceptedTenure =
        offer?.acceptedTenureDays ?? 90;

    final acceptedEmi = offer?.acceptedEmiAmount;

    final bankName =
        _readText(bank?.bankName, 'Bank account');

    final accountMasked =
        _readText(bank?.accountMasked, '');

    final steps = <_JourneyStep>[
      _JourneyStep(
        number: 1,
        title: 'Accept loan offer',
        subtitle:
            'Review the approved amount, tenure and repayment details.',
        icon: Icons.thumb_up_alt_outlined,
        isCompleted: workflow?.offerAccepted == true,
        route: '/loan/$lan/offer',
      ),
      _JourneyStep(
        number: 2,
        title: 'Verify bank account',
        subtitle:
            'Complete penny-drop verification for your disbursal account.',
        icon: Icons.account_balance_outlined,
        isCompleted: workflow?.bankVerified == true,
        route: '/loan/$lan/bank',
      ),
      _JourneyStep(
        number: 3,
        title: 'Accept Key Fact Statement',
        subtitle:
            'Review interest, charges and repayment information.',
        icon: Icons.fact_check_outlined,
        isCompleted: workflow?.kfsAccepted == true,
        route: '/loan/$lan/kfs',
      ),
      _JourneyStep(
        number: 4,
        title: 'Register e-NACH mandate',
        subtitle:
            'Set up automatic EMI repayment from your bank account.',
        icon: Icons.sync_alt_rounded,
        isCompleted:
            workflow?.mandateCompleted == true,
        route: '/loan/$lan/mandate',
      ),
      _JourneyStep(
        number: 5,
        title: 'e-Sign loan agreement',
        subtitle:
            'Digitally sign and complete your loan documentation.',
        icon: Icons.draw_outlined,
        isCompleted: workflow?.esignCompleted == true,
        route: '/loan/$lan/esign',
      ),
      _JourneyStep(
        number: 6,
        title: 'Disbursal',
        subtitle:
            'Track the final transfer of your approved loan amount.',
        icon: Icons.currency_rupee_rounded,
        isCompleted:
            workflow?.readyForDisbursal == true,
        route: '/loan/$lan/disbursal',
      ),
    ];

    final completedCount =
        steps.where((step) => step.isCompleted).length;

    final progress =
        steps.isEmpty ? 0.0 : completedCount / steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF033F45),
                Color(0xFF007D74),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF033F45)
                    .withOpacity(0.20),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -30,
                child: _BackgroundCircle(
                  size: 130,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'APPROVED LOAN',
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.68),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              CurrencyUtils.formatAmount(
                                approvedAmount,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lenderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.80),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _LoanSummaryMetric(
                                icon: Icons.schedule_rounded,
                                label: 'Tenure',
                                value: '$acceptedTenure days',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color:
                                  Colors.white.withOpacity(0.15),
                            ),
                            Expanded(
                              child: _LoanSummaryMetric(
                                icon:
                                    Icons.payments_outlined,
                                label: 'Monthly EMI',
                                value: acceptedEmi == null
                                    ? 'To be confirmed'
                                    : CurrencyUtils
                                        .formatAmount(
                                        acceptedEmi,
                                        showDecimals: true,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (accountMasked.isNotEmpty) ...[
                          const SizedBox(height: 13),
                          Divider(
                            height: 1,
                            color:
                                Colors.white.withOpacity(0.14),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color:
                                    Colors.white.withOpacity(0.9),
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$bankName • $accountMasked',
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.82),
                                    fontSize: 12,
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LAN: $lan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.67),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(30),
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
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF033F45)
                    .withOpacity(0.06),
                blurRadius: 20,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightTeal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.primaryTeal,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your next step',
                          style: TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Complete this step to move closer to disbursal.',
                          style: TextStyle(
                            color:
                                AppTheme.textDarkSecondary,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              AppButton(
                text: _getPrimaryButtonLabel(journeyState),
                onPressed: () {
                  _openRoute(journeyState.targetRoute);
                },
                icon: Icons.arrow_forward_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Loan journey',
          subtitle:
              '$completedCount of ${steps.length} steps completed',
          trailing: Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              color: AppTheme.primaryTeal,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppTheme.primaryLightTeal,
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryTeal,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final step = entry.value;

            final isCurrent =
                journeyState.targetRoute == step.route;

            final isLast = index == steps.length - 1;

            return _JourneyStepTile(
              step: step,
              isCurrent: isCurrent,
              isLast: isLast,
              onTap: () {
                _openRoute(step.route);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildApplicationTab({
    required JourneyState journeyState,
    required dynamic customer,
  }) {
    final applicationId = _readText(
      customer?.latestApplicationId,
      '1',
    );

    final applicationStatus = _readText(
      customer?.latestApplicationStatus,
      'IN_PROGRESS',
    );

    final fullName =
        _readText(customer?.fullName, 'Not provided');

    final email =
        _readText(customer?.email, 'Not provided');

    final panNumber =
        _readText(customer?.panNumber, 'Not provided');

    final employmentType =
        _readText(customer?.employmentType, 'Not provided');

    final employerName = _readText(
      customer?.companyName ?? customer?.businessName,
      'Not provided',
    );

    final residentialPincode = _readText(
      customer?.residentialPincode,
      'Not provided',
    );

    final monthlyIncome = customer?.monthlyIncome;

    final panVerified = customer?.panVerified == true;
    final mobileVerified =
        customer?.mobileVerified == true;
    final emailVerified =
        customer?.emailVerified == true;

    final statusUpper = applicationStatus.toUpperCase();

    final applicationSubmitted =
        statusUpper.contains('SUBMITTED') ||
            statusUpper.contains('APPROVED') ||
            statusUpper.contains('SANCTION') ||
            statusUpper.contains('DISBURS');

    final lenderApproved =
        statusUpper.contains('APPROVED') ||
            statusUpper.contains('SANCTION') ||
            statusUpper.contains('DISBURS');

    final basicDetailsComplete =
        fullName != 'Not provided';

    final profileComplete =
        employmentType != 'Not provided' ||
            monthlyIncome != null;

    final addressComplete =
        residentialPincode != 'Not provided';

    final applicationSteps = <_ApplicationStep>[
      _ApplicationStep(
        number: 1,
        title: 'Basic personal details',
        subtitle: 'Name, date of birth, gender and pincode',
        icon: Icons.person_outline_rounded,
        route: '/onboarding/basic-details',
        isCompleted:
            applicationSubmitted || basicDetailsComplete,
      ),
      _ApplicationStep(
        number: 2,
        title: 'PAN verification',
        subtitle: 'Verify your Permanent Account Number',
        icon: Icons.badge_outlined,
        route: '/onboarding/pan',
        isCompleted:
            applicationSubmitted || panVerified,
      ),
      _ApplicationStep(
        number: 3,
        title: 'Profile and income',
        subtitle:
            'Employment, income and organisation details',
        icon: Icons.work_outline_rounded,
        route: '/onboarding/profile',
        isCompleted:
            applicationSubmitted || profileComplete,
      ),
      _ApplicationStep(
        number: 4,
        title: 'Live photo',
        subtitle: 'Selfie capture and liveness verification',
        icon: Icons.face_retouching_natural_outlined,
        route: '/onboarding/live-photo',
        isCompleted: applicationSubmitted,
      ),
      _ApplicationStep(
        number: 5,
        title: 'DigiLocker Aadhaar KYC',
        subtitle: 'Secure Aadhaar verification through DigiLocker',
        icon: Icons.verified_user_outlined,
        route: '/onboarding/digilocker',
        isCompleted: applicationSubmitted,
      ),
      _ApplicationStep(
        number: 6,
        title: 'Address confirmation',
        subtitle: 'Review and confirm your residence address',
        icon: Icons.home_outlined,
        route: '/onboarding/address',
        isCompleted:
            applicationSubmitted || addressComplete,
      ),
      _ApplicationStep(
        number: 7,
        title: 'Review and submit',
        subtitle:
            'Confirm the application before lender submission',
        icon: Icons.task_alt_rounded,
        route: '/onboarding/review',
        isCompleted: applicationSubmitted,
      ),
    ];

    final completedSteps = applicationSteps
        .where((step) => step.isCompleted)
        .length;

    final applicationProgress = applicationSteps.isEmpty
        ? 0.0
        : completedSteps / applicationSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF033F45)
                    .withOpacity(0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLightTeal,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.primaryTeal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application #$applicationId',
                          style: const TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Personal Loan • Fintree Finance',
                          style: TextStyle(
                            color:
                                AppTheme.textDarkSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(
                    status: applicationStatus,
                  ),
                ],
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: applicationProgress,
                  minHeight: 7,
                  backgroundColor:
                      AppTheme.primaryLightTeal,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$completedSteps of ${applicationSteps.length} application steps completed',
                    style: const TextStyle(
                      color: AppTheme.textDarkSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(applicationProgress * 100).round()}%',
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              AppButton(
                text: 'View Application Status',
                isOutlined: true,
                onPressed: () {
                  context.push('/application/status');
                },
                icon: Icons.analytics_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Applicant profile',
          subtitle: 'Personal and income information',
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: lenderApproved
                  ? AppTheme.successBg
                  : AppTheme.primaryLightTeal,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              lenderApproved ? 'Approved' : 'In progress',
              style: TextStyle(
                color: lenderApproved
                    ? AppTheme.successGreen
                    : AppTheme.primaryTeal,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
          ),
          child: Column(
            children: [
              _ProfileDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Applicant name',
                value: fullName,
              ),
              _ProfileDetailRow(
                icon: Icons.email_outlined,
                label: 'Email address',
                value: email,
              ),
              _ProfileDetailRow(
                icon: Icons.badge_outlined,
                label: 'PAN number',
                value: panNumber,
              ),
              _ProfileDetailRow(
                icon: Icons.work_outline_rounded,
                label: 'Employment type',
                value: employmentType,
              ),
              _ProfileDetailRow(
                icon: Icons.business_outlined,
                label: 'Employer / business',
                value: employerName,
              ),
              _ProfileDetailRow(
                icon: Icons.currency_rupee_rounded,
                label: 'Monthly net income',
                value: monthlyIncome == null
                    ? 'Not provided'
                    : CurrencyUtils.formatAmount(
                        monthlyIncome,
                      ),
              ),
              _ProfileDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Residence pincode',
                value: residentialPincode,
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Application journey',
          subtitle: 'Manage and review your application steps',
        ),
        const SizedBox(height: 13),
        ...applicationSteps.map(
          (step) {
            final isCurrent =
                journeyState.targetRoute == step.route;

            return _ApplicationStepTile(
              step: step,
              isCurrent: isCurrent,
              onTap: () {
                _openRoute(step.route);
              },
            );
          },
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';

    return 'Good evening';
  }

  String _getPrimaryButtonLabel(JourneyState state) {
    final route = state.targetRoute;

    if (route.contains('/offer')) {
      return 'Review Approved Loan Offer';
    }

    if (route.contains('/digilocker')) {
      return 'Complete DigiLocker KYC';
    }

    if (route.contains('/address')) {
      return 'Confirm Residence Address';
    }

    if (route.contains('/bank')) {
      return 'Verify Bank Account';
    }

    if (route.contains('/kfs')) {
      return 'Review & Accept KFS';
    }

    if (route.contains('/mandate')) {
      return 'Register e-NACH Mandate';
    }

    if (route.contains('/esign')) {
      return 'Complete Agreement e-Sign';
    }

    if (route.contains('/disbursal')) {
      return 'View Disbursal Status';
    }

    if (route.contains('/application/status')) {
      return 'Check Application Status';
    }

    if (route.contains('/onboarding')) {
      return 'Continue Loan Application';
    }

    return 'Start Application';
  }

  String _readText(
    dynamic value,
    String fallback,
  ) {
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
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _shortStatus(String value) {
    final upperValue = value.toUpperCase();

    if (upperValue.contains('APPROVED')) {
      return 'APPROVED';
    }

    if (upperValue.contains('DISBURS')) {
      return 'DISBURSED';
    }

    if (upperValue.contains('REJECT')) {
      return 'REVIEWED';
    }

    return 'IN PROGRESS';
  }
}

class _DashboardTabButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DashboardTabButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? AppTheme.primaryTeal
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.16)
                      : AppTheme.primaryLightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textDarkPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withOpacity(0.72)
                            : AppTheme.textDarkSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.68),
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
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
        ? AppTheme.successGreen
        : isCurrent
            ? AppTheme.primaryTeal
            : AppTheme.textMuted;

    final statusBackground = step.isCompleted
        ? AppTheme.successBg
        : isCurrent
            ? AppTheme.primaryLightTeal
            : const Color(0xFFF3F6F6);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor.withOpacity(0.25),
                    ),
                  ),
                  child: step.isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          color: statusColor,
                          size: 18,
                        )
                      : Text(
                          '${step.number}',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      color: step.isCompleted
                          ? AppTheme.successGreen
                              .withOpacity(0.25)
                          : AppTheme.borderLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 12,
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primaryTeal
                            : AppTheme.borderLight,
                        width: isCurrent ? 1.4 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryTeal
                                    .withOpacity(0.08),
                                blurRadius: 16,
                                offset:
                                    const Offset(0, 7),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius:
                                BorderRadius.circular(13),
                          ),
                          child: Icon(
                            step.icon,
                            color: statusColor,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      style: const TextStyle(
                                        color: AppTheme
                                            .textDarkPrimary,
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color: AppTheme
                                            .primaryLightTeal,
                                        borderRadius:
                                            BorderRadius
                                                .circular(20),
                                      ),
                                      child: const Text(
                                        'NEXT',
                                        style: TextStyle(
                                          color: AppTheme
                                              .primaryTeal,
                                          fontSize: 8.5,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                step.subtitle,
                                style: const TextStyle(
                                  color: AppTheme
                                      .textDarkSecondary,
                                  fontSize: 10.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                          size: 21,
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
    final color = isVerified
        ? AppTheme.successGreen
        : AppTheme.warningOrange;

    final background = isVerified
        ? AppTheme.successBg
        : AppTheme.warningBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textDarkPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
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

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryTeal,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: AppTheme.borderLight,
          ),
      ],
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
        ? AppTheme.successGreen
        : isCurrent
            ? AppTheme.primaryTeal
            : AppTheme.textMuted;

    final background = step.isCompleted
        ? AppTheme.successBg
        : isCurrent
            ? AppTheme.primaryLightTeal
            : const Color(0xFFF4F7F7);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? AppTheme.primaryTeal
                    : AppTheme.borderLight,
                width: isCurrent ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                      child: Icon(
                        step.icon,
                        color: color,
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: step.isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 11,
                              )
                            : Text(
                                '${step.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: const TextStyle(
                                color:
                                    AppTheme.textDarkPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme
                                    .primaryLightTeal,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color:
                                      AppTheme.primaryTeal,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.subtitle,
                        style: const TextStyle(
                          color:
                              AppTheme.textDarkSecondary,
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  step.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: color,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}