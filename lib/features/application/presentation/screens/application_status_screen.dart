import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/models/customer_model.dart';
import '../../../../core/models/post_approval_model.dart';
import '../../../dashboard/presentation/journey_controller.dart';


class ApplicationStatusScreen extends ConsumerStatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  ConsumerState<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends ConsumerState<ApplicationStatusScreen> {
  bool _isAutoPolling = false;

  @override
  void initState() {
    super.initState();
    // Start polling if we're in decision processing state
    Future.microtask(() => _maybeStartPolling());
  }

  void _refresh() async {
    await ref.read(journeyControllerProvider.notifier).syncCustomerState();
    _maybeStartPolling();
  }

  void _maybeStartPolling() {
    final customer = ref.read(journeyControllerProvider).customer;
    final nextStep = customer?.nextPermittedStep;
    final appStatus = customer?.latestApplicationStatus;
    
    // Auto-poll if lender decision is processing or pending credit review
    if (nextStep == 'LENDER_DECISION_PROCESSING' ||
        nextStep == 'LENDER_CREATE_PROCESSING' ||
        nextStep == 'LENDER_UPDATE_PROCESSING' ||
        nextStep == 'APPROVAL_PROCESSING' ||
        appStatus == 'SUBMITTED' ||
        appStatus == 'PENDING_CREDIT_REVIEW' ||
        appStatus == 'LENDER_REVIEW') {
      if (!_isAutoPolling) _startAutoPolling();
    }
  }

  void _startAutoPolling() async {
    if (!mounted) return;
    setState(() => _isAutoPolling = true);

    const maxAttempts = 30; // 30 * 4s = 120s (2 minutes timeout)
    int attempts = 0;

    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      attempts++;

      try {
        final customerApi = ref.read(customerApiProvider);
        final profileRes = await customerApi.getCustomerProfile();
        dynamic journeyData = profileRes['journey'] ?? profileRes['data']?['journey'];
        String? currentStep = journeyData?['currentStep'];
        String? appStatus = journeyData?['applicationStatus'];
        String? platformLan = journeyData?['platformLan'];

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        if (!mounted) break;

        final customer = ref.read(journeyControllerProvider).customer;
        currentStep ??= customer?.nextPermittedStep;
        appStatus ??= customer?.latestApplicationStatus;
        platformLan ??= customer?.latestLan ?? customer?.platformLan;

        if (currentStep == 'PRE_APPROVAL_OFFER_SELECTION' || appStatus == 'LENDER_PRE_APPROVED' || appStatus == 'LENDER_APPROVED') {
          final effectiveLan = (platformLan != null && platformLan.isNotEmpty) ? platformLan : 'default';
          PushNotificationService().sendLoanApprovedNotification(lan: effectiveLan);
          if (mounted) {
            context.go('/loan/$effectiveLan/offer?isPreApproval=true');
          }
          break;
        }

        if (appStatus == 'LENDER_REJECTED' || appStatus == 'REJECTED') {
          break;
        }
      } catch (e) {
        debugPrint('[StatusPoll] Error polling profile: $e');
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      }
    }

    if (mounted) setState(() => _isAutoPolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    
    final rawStatus = customer?.latestApplicationStatus;
    String appStatus = (rawStatus != null && rawStatus.isNotEmpty)
        ? rawStatus
        : ((customer?.assessmentFeePaid ?? false) ? 'ASSESSMENT_FEE_PAID' : 'IN_PROGRESS');
    final nextStep = customer?.nextPermittedStep;
    final lan = customer?.latestLan ?? customer?.platformLan;

    if (journeyState.isLoading) {
      return const Scaffold(body: AppLoader(message: 'Checking application status...'));
    }

    final bool isRejection = appStatus == 'LENDER_REJECTED' || appStatus == 'REJECTED';
    final bool isProcessing = _isAutoPolling ||
        nextStep == 'LENDER_DECISION_PROCESSING' ||
        nextStep == 'LENDER_CREATE_PROCESSING' ||
        nextStep == 'LENDER_UPDATE_PROCESSING' ||
        nextStep == 'APPROVAL_PROCESSING' ||
        appStatus == 'SUBMITTED' ||
        appStatus == 'PENDING_CREDIT_REVIEW' ||
        appStatus == 'LENDER_REVIEW';
    final bool isDisbursed = appStatus.toUpperCase() == 'DISBURSED' ||
        customer?.latestLoanStatus == 'DISBURSED' ||
        journeyState.postApproval?.workflow.currentStep == 'DISBURSED' ||
        journeyState.postApproval?.loan.disbursalCompletedAt != null;

    return Scaffold(
      appBar: AppHeader(
        title: isProcessing
            ? 'Underwriting in Progress'
            : (isDisbursed ? 'Loan Disbursed' : 'Application Status'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              if (isDisbursed)
                _buildDisbursedCelebrationCard(context, customer, journeyState.postApproval, lan ?? '')
              else ...[
                if (isProcessing)
                  SvgPicture.asset(
                    'lib/assets/images/illustrations/Loading-rafiki.svg',
                    height: 140,
                  )
                else if (appStatus.contains('APPROVED') || appStatus.contains('COMPLETED'))
                  SvgPicture.asset(
                    'lib/assets/images/illustrations/Completed-pana.svg',
                    height: 140,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.15), width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryTeal.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      _getStatusIcon(appStatus),
                      size: 64,
                      color: _getStatusIconColor(appStatus),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  isProcessing ? 'We are processing your application with the lender...' : _getStatusTitle(appStatus),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                ),
                const SizedBox(height: 10),
                Text(
                  isProcessing
                      ? 'This usually takes 10 to 30 seconds. Please do not close or refresh this page.'
                      : _getStatusDescription(appStatus),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _infoRow('Lender', customer?.allocatedLenderName ?? 'Fintree Finance Private Limited'),
                        const Divider(height: 16),
                        _infoRow('Status', appStatus, isBadge: true),
                        if (lan != null && lan.isNotEmpty) ...[
                          const Divider(height: 16),
                          _infoRow('Loan Account No. (LAN)', lan),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (isRejection) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Application Not Approved',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed, fontSize: 15),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your application does not currently satisfy lender policy thresholds. You may re-apply after 90 days or contact support for assistance.',
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 13, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Return to Dashboard',
                    onPressed: () => context.go('/dashboard'),
                    icon: Icons.home_rounded,
                  ),
                ] else ...[
                  _buildActionButtons(appStatus, nextStep, lan, context, journeyState),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'LENDER_APPROVED':
      case 'APPROVED':
        return Icons.check_circle_rounded;
      case 'LENDER_PRE_APPROVED':
      case 'PRE_APPROVED':
        return Icons.verified_rounded;
      case 'ASSESSMENT_FEE_PAID':
        return Icons.task_alt_rounded;
      case 'IN_PROGRESS':
      case 'DRAFT':
      case 'PENDING_DOCUMENTS':
      case 'INITIATED':
        return Icons.assignment_outlined;
      case 'LENDER_REVIEW':
      case 'UNDER_REVIEW':
        return Icons.rate_review_rounded;
      case 'PENDING_CREDIT_REVIEW':
        return Icons.fact_check_rounded;
      case 'LENDER_REJECTED':
      case 'REJECTED':
        return Icons.cancel_rounded;
      case 'SUBMITTED':
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _getStatusIconColor(String status) {
    switch (status.toUpperCase()) {
      case 'LENDER_APPROVED':
      case 'APPROVED':
      case 'LENDER_PRE_APPROVED':
      case 'PRE_APPROVED':
      case 'ASSESSMENT_FEE_PAID':
        return AppTheme.successGreen;
      case 'IN_PROGRESS':
      case 'DRAFT':
      case 'PENDING_DOCUMENTS':
      case 'INITIATED':
      case 'LENDER_REVIEW':
      case 'UNDER_REVIEW':
        return AppTheme.primaryTeal;
      case 'PENDING_CREDIT_REVIEW':
      case 'SUBMITTED':
        return AppTheme.warningOrange;
      case 'LENDER_REJECTED':
      case 'REJECTED':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryTeal;
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toUpperCase()) {
      case 'LENDER_APPROVED':
      case 'APPROVED':
        return 'Application Approved!';
      case 'LENDER_PRE_APPROVED':
      case 'PRE_APPROVED':
        return 'Application Pre-Approved!';
      case 'PENDING_CREDIT_REVIEW':
        return 'Final Credit Review';
      case 'LENDER_REVIEW':
      case 'UNDER_REVIEW':
        return 'Under Lender Review';
      case 'SUBMITTED':
        return 'Application Submitted';
      case 'ASSESSMENT_FEE_PAID':
        return 'Assessment Fee Paid';
      case 'IN_PROGRESS':
      case 'DRAFT':
      case 'PENDING_DOCUMENTS':
      case 'INITIATED':
        return 'Application In Progress';
      case 'LENDER_REJECTED':
      case 'REJECTED':
        return 'Application Decision';
      default:
        return 'Application Status';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toUpperCase()) {
      case 'LENDER_APPROVED':
      case 'APPROVED':
        return 'Congratulations! Fintree Finance has approved your loan application.';
      case 'LENDER_PRE_APPROVED':
      case 'PRE_APPROVED':
        return 'Great news! You have been pre-approved. Please review and select your loan offer.';
      case 'PENDING_CREDIT_REVIEW':
        return 'Your selected offer is undergoing final credit assessment by the lender.';
      case 'LENDER_REVIEW':
      case 'UNDER_REVIEW':
        return 'Your application is currently being reviewed by the lender underwriting team.';
      case 'SUBMITTED':
        return 'Your application has been submitted and is awaiting lender processing.';
      case 'ASSESSMENT_FEE_PAID':
        return 'Your lender assessment fee has been paid successfully. Please complete the remaining onboarding steps to submit your application.';
      case 'IN_PROGRESS':
      case 'DRAFT':
      case 'PENDING_DOCUMENTS':
      case 'INITIATED':
        return 'Your loan application is in progress. Please complete all required verification steps to submit your application for review.';
      case 'LENDER_REJECTED':
      case 'REJECTED':
        return 'Unfortunately, your application does not satisfy current lender policy thresholds.';
      default:
        return 'Check your current application status and complete any pending onboarding steps.';
    }
  }

  Widget _buildActionButtons(String appStatus, String? nextStep, String? lan, BuildContext context, JourneyState journeyState) {
    final statusUpper = appStatus.toUpperCase();

    // If backend is still processing lender decision - show auto-polling indicator
    if (_isAutoPolling ||
        nextStep == 'LENDER_DECISION_PROCESSING' ||
        nextStep == 'LENDER_CREATE_PROCESSING' ||
        nextStep == 'APPROVAL_PROCESSING') {
      return Column(
        children: [
          const LinearProgressIndicator(color: AppTheme.primaryTeal),
          const SizedBox(height: 12),
          Text(
            _isAutoPolling
                ? 'Checking lender decision automatically…'
                : 'Your application is with the lender for decision.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Refresh Now',
            isOutlined: true,
            onPressed: _refresh,
            icon: Icons.refresh_rounded,
          ),
        ],
      );
    }

    if (statusUpper == 'LENDER_APPROVED' || statusUpper == 'APPROVED') {
      if (lan != null && lan.isNotEmpty) {
        return AppButton(
          text: 'View Post-Approval Journey',
          onPressed: () => context.push('/dashboard'),
          icon: Icons.arrow_forward_rounded,
        );
      } else {
        return const Card(
          color: AppTheme.warningBg,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Your application is approved. Your loan account number is being generated.',
              style: TextStyle(color: AppTheme.warningOrange, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    if (statusUpper == 'LENDER_PRE_APPROVED' || statusUpper == 'PRE_APPROVED') {
      final effectiveLan = (lan != null && lan.isNotEmpty) ? lan : 'default';
      return AppButton(
        text: 'View Pre-Approved Offer',
        onPressed: () => context.push('/loan/$effectiveLan/offer?isPreApproval=true'),
        icon: Icons.local_offer_rounded,
      );
    }

    final bool isUnsubmitted = ['ASSESSMENT_FEE_PAID', 'IN_PROGRESS', 'DRAFT', 'PENDING_DOCUMENTS', 'INITIATED'].contains(statusUpper);

    if (isUnsubmitted) {
      return Column(
        children: [
          AppButton(
            text: 'Continue Application',
            onPressed: () {
              final target = journeyState.targetRoute;
              if (target.isNotEmpty && target != '/login' && target != '/application/status') {
                context.push(target);
              } else {
                context.push('/onboarding/basic-details');
              }
            },
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Refresh Status',
            isOutlined: true,
            onPressed: _refresh,
            icon: Icons.refresh_rounded,
          ),
        ],
      );
    }

    return AppButton(
      text: 'Refresh Status',
      onPressed: _refresh,
      icon: Icons.refresh_rounded,
    );
  }

  Widget _infoRow(String label, String val, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
        const SizedBox(width: 8),
        if (isBadge)
          AppStatusBadge(status: val)
        else
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildDisbursedCelebrationCard(
    BuildContext context,
    CustomerModel? customer,
    PostApprovalJourneyModel? postApproval,
    String lan,
  ) {
    final loan = postApproval?.loan;
    final bank = postApproval?.bank;
    final num? rawAmt = loan?.disbursalAmount ?? loan?.approvedAmount ?? postApproval?.offer.approvedAmount;
    final double? amount = (rawAmt != null && rawAmt > 0) ? rawAmt.toDouble() : null;
    final String utr = loan?.disbursalUtr ?? 'N/A';
    final String bankName = bank?.bankName ?? 'Bank Account';
    final String accountMasked = bank?.accountMasked ?? '';

    return Column(
      children: [
        SvgPicture.asset(
          'lib/assets/images/illustrations/Completed-pana.svg',
          height: 140,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF0F5A47)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF064E3B).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Color(0xFF34D399),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loan Disbursed Successfully! 🎉',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Funds have been credited directly to your bank account.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Disbursed Net Amount',
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            amount != null ? CurrencyUtils.formatAmount(amount) : '₹5,000',
                            textAlign: TextAlign.right,
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UTR Reference',
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  utr,
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (utr != 'N/A') ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: utr));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('UTR reference copied to clipboard!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, color: Color(0xFF34D399), size: 14),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (bankName.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destination Bank',
                            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              accountMasked.isNotEmpty ? '$bankName (..$accountMasked)' : bankName,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/loan/${lan.isNotEmpty ? lan : 'FTPL00000011'}/loan-details'),
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text(
                        'View RPS Schedule',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.home_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Dashboard',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
