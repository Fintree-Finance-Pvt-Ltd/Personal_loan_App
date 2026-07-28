import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class MandateScreen extends ConsumerStatefulWidget {
  final String lan;

  const MandateScreen({super.key, required this.lan});

  @override
  ConsumerState<MandateScreen> createState() => _MandateScreenState();
}

class _MandateScreenState extends ConsumerState<MandateScreen> {
  bool _isInitiating = false;
  bool _isChecking = false;
  String? _errorMessage;

  void _initiateMandate() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/mandate/initiate',
        data: {'customerId': customerId},
      );

      final data = res['data'] ?? res;
      final mandateUrl = data['mandateUrl'] ?? data['url'];

      if (mandateUrl != null) {
        final uri = Uri.parse(mandateUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  void _checkMandateStatus() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.get(
        '/customer/loans/${widget.lan}/mandate/status?customerId=$customerId',
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        final completed = ref.read(journeyControllerProvider).postApproval?.workflow.mandateCompleted == true;
        if (completed) {
          context.push('/loan/${widget.lan}/esign');
        } else {
          setState(() {
            _errorMessage = 'Mandate registration is pending. Complete registration in bank page and retry.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(journeyControllerProvider).postApproval?.workflow;
    final isCompleted = workflow?.mandateCompleted == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('e-NACH Mandate Registration'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Auto-Debit (e-NACH) Mandate',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register automated repayment mandate with your bank for hassle-free EMI repayments.',
                style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mandate Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          AppStatusBadge(status: isCompleted ? 'COMPLETED' : 'PENDING'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Mandate Type', 'e-NACH / NetBanking AutoDebit'),
                      _row('Purpose', 'Personal Loan EMI Repayment'),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                ),
              ],
              const Spacer(),
              if (isCompleted)
                AppButton(
                  text: 'Proceed to Agreement e-Sign',
                  onPressed: () => context.push('/loan/${widget.lan}/esign'),
                  icon: Icons.arrow_forward_rounded,
                )
              else if (_isChecking)
                const AppLoader(message: 'Checking mandate status with bank gateway...')
              else ...[
                AppButton(
                  text: 'Initiate e-NACH Mandate',
                  isLoading: _isInitiating,
                  onPressed: _initiateMandate,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Check Mandate Completion',
                  isOutlined: true,
                  onPressed: _checkMandateStatus,
                  icon: Icons.refresh_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
