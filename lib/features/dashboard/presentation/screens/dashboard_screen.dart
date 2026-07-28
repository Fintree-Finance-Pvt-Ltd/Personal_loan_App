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
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    final postApproval = journeyState.postApproval;
    final offer = postApproval?.offer;
    final bank = postApproval?.bank;
    final workflow = postApproval?.workflow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(journeyControllerProvider.notifier).syncCustomerState();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Welcome Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryTeal,
                      child: Text(
                        (customer?.fullName != null && customer!.fullName!.isNotEmpty)
                            ? customer.fullName![0].toUpperCase()
                            : 'C',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${customer?.fullName ?? 'Valued Customer'}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Mobile: ${customer?.mobileNumber ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stage Manager Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryTeal,
                    labelColor: AppTheme.primaryTeal,
                    unselectedLabelColor: AppTheme.textDarkSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Post-Approval Stage'),
                      Tab(text: 'Application Stage'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stage View Content
                SizedBox(
                  height: 640,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: POST-APPROVAL STAGE MANAGER
                      _buildPostApprovalTab(context, journeyState, postApproval, offer, bank, workflow),

                      // TAB 2: APPLICATION STAGE MANAGER
                      _buildApplicationTab(context, journeyState, customer),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostApprovalTab(
    BuildContext context,
    JourneyState journeyState,
    dynamic postApproval,
    dynamic offer,
    dynamic bank,
    dynamic workflow,
  ) {
    final lan = postApproval?.loan.lan ?? 'FFPL000001';
    final currentStep = workflow?.currentStep ?? 'APPROVAL_SUMMARY';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Loan Summary Card
          Card(
            color: AppTheme.primaryLightTeal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LAN: $lan',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDarkTeal),
                      ),
                      AppStatusBadge(status: currentStep),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyUtils.formatAmount(postApproval?.loan.approvedAmount ?? 500000),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkTeal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lender: ${postApproval?.lender.name ?? 'Fintree Finance Private Limited'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                  ),
                  const Divider(height: 20),
                  _row('Tenure Selected', '${offer?.acceptedTenureDays ?? 90} Days'),
                  if (offer?.acceptedEmiAmount != null)
                    _row('Monthly EMI', CurrencyUtils.formatAmount(offer.acceptedEmiAmount, showDecimals: true)),
                  if (bank?.accountMasked != null)
                    _row('Verified Bank', '${bank.bankName ?? 'HDFC Bank'} (${bank.accountMasked})'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Active Action Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Next Step Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text(
                    'Complete your current post-approval milestone to proceed to loan disbursal.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    text: _getPrimaryButtonLabel(journeyState),
                    onPressed: () => context.push(journeyState.targetRoute),
                    icon: Icons.arrow_forward_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Interactive Post-Approval Milestones List
          const Text('Manage Post-Approval Milestones', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
          const SizedBox(height: 10),
          _milestoneTile(context, stepNum: 1, title: 'Offer Acceptance', isDone: workflow?.offerAccepted == true, route: '/loan/$lan/offer'),
          _milestoneTile(context, stepNum: 2, title: 'DigiLocker Aadhaar KYC', isDone: workflow?.digilockerVerified == true, route: '/loan/$lan/digilocker'),
          _milestoneTile(context, stepNum: 3, title: 'Address Confirmation', isDone: workflow?.addressConfirmed == true, route: '/loan/$lan/address'),
          _milestoneTile(context, stepNum: 4, title: 'Bank Account Penny Drop', isDone: workflow?.bankVerified == true, route: '/loan/$lan/bank'),
          _milestoneTile(context, stepNum: 5, title: 'Key Fact Statement (KFS)', isDone: workflow?.kfsAccepted == true, route: '/loan/$lan/kfs'),
          _milestoneTile(context, stepNum: 6, title: 'e-NACH Mandate Registration', isDone: workflow?.mandateCompleted == true, route: '/loan/$lan/mandate'),
          _milestoneTile(context, stepNum: 7, title: 'Loan Agreement e-Sign', isDone: workflow?.esignCompleted == true, route: '/loan/$lan/esign'),
          _milestoneTile(context, stepNum: 8, title: 'Instant Disbursal Request', isDone: workflow?.readyForDisbursal == true, route: '/loan/$lan/disbursal'),
        ],
      ),
    );
  }

  Widget _buildApplicationTab(BuildContext context, JourneyState journeyState, dynamic customer) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Application Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('App ID: #${customer?.latestApplicationId ?? '1'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      AppStatusBadge(status: customer?.latestApplicationStatus ?? 'LENDER_APPROVED'),
                    ],
                  ),
                  const Divider(height: 20),
                  _row('Product', 'Personal Loan'),
                  _row('Lender', 'Fintree Finance Private Limited'),
                  _row('PAN Verification', customer?.panVerified == true ? 'VERIFIED' : 'PENDING'),
                  _row('Mobile Verification', customer?.mobileVerified == true ? 'VERIFIED' : 'PENDING'),
                  _row('Email Verification', customer?.emailVerified == true ? 'VERIFIED' : 'PENDING'),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Check Application Status Details',
                    isOutlined: true,
                    onPressed: () => context.push('/application/status'),
                    icon: Icons.analytics_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Applicant Profile & Income Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Applicant Profile & Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Divider(height: 20),
                  _row('Applicant Name', customer?.fullName ?? 'N/A'),
                  _row('Email', customer?.email ?? 'N/A'),
                  _row('PAN Number', customer?.panNumber ?? 'N/A'),
                  _row('Employment Type', customer?.employmentType ?? 'SALARIED'),
                  _row('Employer Name', customer?.companyName ?? customer?.businessName ?? 'Vishal Fintree'),
                  _row('Monthly Net Income', CurrencyUtils.formatAmount(customer?.monthlyIncome ?? 234567)),
                  _row('Residence Pincode', customer?.residentialPincode ?? '400053'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Application Stages Quick Actions
          const Text('Manage Application Stage Steps', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
          const SizedBox(height: 10),
          _stageTile(context, stepNum: 1, title: 'Basic Personal Details', subtitle: 'Name, DOB, Gender & Pincode', route: '/onboarding/basic-details'),
          _stageTile(context, stepNum: 2, title: 'PAN Verification', subtitle: '10-digit PAN Validation', route: '/onboarding/pan'),
          _stageTile(context, stepNum: 3, title: 'Profile & Income Details', subtitle: 'Employment, Income & Firm', route: '/onboarding/profile'),
          _stageTile(context, stepNum: 4, title: 'Live Photo & Liveness Check', subtitle: 'Selfie Capture & AI Check', route: '/onboarding/live-photo'),
          _stageTile(context, stepNum: 5, title: 'Review & Submit Application', subtitle: 'Final Submission to Lender', route: '/onboarding/review'),
        ],
      ),
    );
  }

  Widget _milestoneTile(BuildContext context, {required int stepNum, required String title, required bool isDone, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: isDone ? AppTheme.successBg : AppTheme.backgroundLight,
          child: Icon(isDone ? Icons.check_rounded : Icons.lock_outline_rounded, size: 14, color: isDone ? AppTheme.successGreen : AppTheme.textMuted),
        ),
        title: Text(
          '$stepNum. $title',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDarkPrimary),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
        onTap: () => context.push(route),
      ),
    );
  }

  Widget _stageTile(BuildContext context, {required int stepNum, required String title, required String subtitle, required String route}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryLightTeal,
          child: Text('$stepNum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDarkPrimary), overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textDarkSecondary), overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryTeal),
        onTap: () => context.push(route),
      ),
    );
  }

  String _getPrimaryButtonLabel(JourneyState state) {
    final route = state.targetRoute;
    if (route.contains('/offer')) return 'Review Approved Loan Offer';
    if (route.contains('/digilocker')) return 'Complete DigiLocker KYC';
    if (route.contains('/address')) return 'Confirm Residence Address';
    if (route.contains('/bank')) return 'Verify Bank Account';
    if (route.contains('/kfs')) return 'Review & Accept KFS';
    if (route.contains('/mandate')) return 'Register e-NACH Mandate';
    if (route.contains('/esign')) return 'Complete Agreement e-Sign';
    if (route.contains('/disbursal')) return 'View Disbursal Status';
    if (route.contains('/application/status')) return 'Check Application Status';
    if (route.contains('/onboarding')) return 'Continue Loan Application';
    return 'Start Application';
  }

  Widget _row(String label, String val, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
