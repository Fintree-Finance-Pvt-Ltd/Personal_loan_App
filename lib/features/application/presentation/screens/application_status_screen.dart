import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
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

    const maxAttempts = 36; // 36 * 5s = 180 seconds (3 mins max)
    int attempts = 0;

    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) break;
      attempts++;

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      if (!mounted) break;

      final customer = ref.read(journeyControllerProvider).customer;
      final nextStep = customer?.nextPermittedStep;
      final appStatus = customer?.latestApplicationStatus;
      final lan = customer?.latestLan ?? customer?.platformLan;

      // Resolved to pre-approved — go to offer page
      if (nextStep == 'PRE_APPROVAL_OFFER_SELECTION' ||
          appStatus == 'LENDER_PRE_APPROVED') {
        if (mounted) {
          if (lan != null && lan.isNotEmpty) {
            context.go('/loan/$lan/offer?isPreApproval=true');
          } else {
            context.go('/onboarding/offer');
          }
        }
        break;
      }

      // Resolved to Lender Approved — stop polling (UI will present post-approval start button)
      if (appStatus == 'LENDER_APPROVED') {
        break;
      }

      // Terminal rejection or support step
      if (nextStep == 'INTEGRATION_SUPPORT' ||
          appStatus == 'LENDER_REJECTED' ||
          appStatus == 'REJECTED') {
        break;
      }

      // Still processing — keep looping
      final isStillProcessing = nextStep == 'LENDER_DECISION_PROCESSING' ||
          nextStep == 'LENDER_CREATE_PROCESSING' ||
          nextStep == 'LENDER_UPDATE_PROCESSING' ||
          nextStep == 'APPROVAL_PROCESSING' ||
          appStatus == 'SUBMITTED' ||
          appStatus == 'PENDING_CREDIT_REVIEW' ||
          appStatus == 'LENDER_REVIEW';
          
      if (!isStillProcessing) break;
    }

    if (mounted) setState(() => _isAutoPolling = false);
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    
    String appStatus = customer?.latestApplicationStatus ?? 'SUBMITTED';
    final nextStep = customer?.nextPermittedStep;
    final lan = customer?.latestLan ?? customer?.platformLan;



    if (journeyState.isLoading) {
      return const Scaffold(body: AppLoader(message: 'Checking application status...'));
    }

    return Scaffold(
      appBar: AppHeader(
        title: 'Application Status',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Icon(
                  _isAutoPolling || nextStep == 'LENDER_DECISION_PROCESSING' ||
                      nextStep == 'LENDER_CREATE_PROCESSING' ||
                      nextStep == 'APPROVAL_PROCESSING'
                      ? Icons.sync_rounded
                      : (appStatus == 'LENDER_APPROVED'
                          ? Icons.check_circle_rounded
                          : (appStatus == 'REJECTED' ? Icons.cancel_rounded : Icons.hourglass_top_rounded)),
                  size: 64,
                  color: _isAutoPolling
                      ? AppTheme.primaryTeal
                      : (appStatus == 'LENDER_APPROVED'
                          ? AppTheme.successGreen
                          : (appStatus == 'REJECTED' ? AppTheme.errorRed : AppTheme.warningOrange)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _getStatusTitle(appStatus),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(appStatus),
                style: const TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _infoRow('Lender', 'Fintree Finance Private Limited'),
                      const Divider(height: 16),
                      _infoRow('Status', appStatus, isBadge: true),
                      if (lan != null) ...[
                        const Divider(height: 16),
                        _infoRow('Loan Account No. (LAN)', lan),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _buildActionButtons(appStatus, nextStep, lan, context),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTitle(String status) {
    if (status == 'LENDER_APPROVED') return 'Application Approved!';
    if (status == 'REJECTED') return 'Application Decision';
    if (status == 'LENDER_PRE_APPROVED') return 'Pre-Approved!';
    if (status == 'PENDING_CREDIT_REVIEW') return 'Final Credit Review';
    if (status == 'LENDER_REVIEW') return 'Under Lender Review';
    if (status == 'SUBMITTED') return 'Application Processing';
    return 'Application Submitted';
  }

  String _getStatusDescription(String status) {
    if (status == 'LENDER_APPROVED') return 'Congratulations! Fintree Finance has approved your loan application.';
    if (status == 'REJECTED') return 'Unfortunately your application does not meet current lender eligibility criteria.';
    if (status == 'LENDER_PRE_APPROVED') return 'Great news! You have been pre-approved. Please review and select your offer.';
    if (status == 'PENDING_CREDIT_REVIEW') return 'Your selected offer is undergoing final credit review by the lender.';
    if (status == 'LENDER_REVIEW') return 'Your application is currently being reviewed by the lender.';
    if (status == 'SUBMITTED') return 'Your application has been submitted. We are processing your lender decision. This may take a moment…';
    return 'Your application has been successfully submitted and is awaiting lender review.';
  }

  Widget _buildActionButtons(String appStatus, String? nextStep, String? lan, BuildContext context) {
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
    } else if (appStatus == 'LENDER_APPROVED' && lan != null) {
      return AppButton(
        text: 'View Post-Approval Journey',
        onPressed: () => context.push('/dashboard'),
        icon: Icons.arrow_forward_rounded,
      );
    } else if (appStatus == 'LENDER_APPROVED' && lan == null) {
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
    } else if (appStatus == 'LENDER_PRE_APPROVED' && lan != null) {
      return AppButton(
        text: 'View Pre-Approved Offer',
        onPressed: () => context.push('/loan/$lan/offer?isPreApproval=true'),
        icon: Icons.local_offer_rounded,
      );
    } else {
      return AppButton(
        text: 'Refresh Status',
        onPressed: _refresh,
        icon: Icons.refresh_rounded,
      );
    }
  }

  Widget _infoRow(String label, String val, {bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
        if (isBadge) AppStatusBadge(status: val) else Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
      ],
    );
  }
}
