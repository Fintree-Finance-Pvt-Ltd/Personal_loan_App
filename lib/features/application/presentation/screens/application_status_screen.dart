import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ApplicationStatusScreen extends ConsumerStatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  ConsumerState<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends ConsumerState<ApplicationStatusScreen> {
  bool _isSimulating = false;

  void _refresh() async {
    await ref.read(journeyControllerProvider.notifier).syncCustomerState();
  }

  void _simulateApproval() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() => _isSimulating = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/$customerId/simulate-lender-approval',
        data: {'customerId': customerId, 'amount': 50000},
      );
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journeyState = ref.watch(journeyControllerProvider);
    final customer = journeyState.customer;
    final appStatus = customer?.latestApplicationStatus ?? 'SUBMITTED';
    final lan = customer?.latestLan;

    if (journeyState.isLoading) {
      return const Scaffold(body: AppLoader(message: 'Checking application status...'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
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
                  appStatus == 'LENDER_APPROVED'
                      ? Icons.check_circle_rounded
                      : (appStatus == 'REJECTED' ? Icons.cancel_rounded : Icons.hourglass_top_rounded),
                  size: 64,
                  color: appStatus == 'LENDER_APPROVED'
                      ? AppTheme.successGreen
                      : (appStatus == 'REJECTED' ? AppTheme.errorRed : AppTheme.warningOrange),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                appStatus == 'LENDER_APPROVED'
                    ? 'Application Approved!'
                    : (appStatus == 'REJECTED' ? 'Application Decision' : 'Application Under Review'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                appStatus == 'LENDER_APPROVED'
                    ? 'Congratulations! Fintree Finance has approved your loan application.'
                    : (appStatus == 'REJECTED'
                        ? 'Unfortunately your application does not meet current lender eligibility criteria.'
                        : 'Your application has been submitted to lender Fintree Finance for review.'),
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
              if (appStatus == 'LENDER_APPROVED' && lan != null)
                AppButton(
                  text: 'View Loan Offer',
                  onPressed: () => context.push('/loan/$lan/offer'),
                  icon: Icons.arrow_forward_rounded,
                )
              else if (appStatus == 'LENDER_APPROVED' && lan == null)
                const Card(
                  color: AppTheme.warningBg,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Your application is approved. Your loan account number is being generated.',
                      style: TextStyle(color: AppTheme.warningOrange, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (appStatus == 'SUBMITTED') ...[
                AppButton(
                  text: 'Simulate Lender Approval (UAT Test)',
                  isLoading: _isSimulating,
                  isOutlined: true,
                  onPressed: _simulateApproval,
                  icon: Icons.flash_on_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Refresh Status',
                  onPressed: _refresh,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
