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

class EsignScreen extends ConsumerStatefulWidget {
  final String lan;

  const EsignScreen({super.key, required this.lan});

  @override
  ConsumerState<EsignScreen> createState() => _EsignScreenState();
}

class _EsignScreenState extends ConsumerState<EsignScreen> {
  bool _isInitiating = false;
  bool _isChecking = false;
  String? _errorMessage;

  void _initiateEsign() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/esign/initiate',
        data: {'customerId': customerId},
      );

      final data = res['data'] ?? res;
      final esignUrl = data['esignUrl'] ?? data['url'];

      if (esignUrl != null) {
        final uri = Uri.parse(esignUrl);
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

  void _checkEsignStatus() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.get('/customer/loans/${widget.lan}/esign/status');

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        final completed = ref.read(journeyControllerProvider).postApproval?.workflow.esignCompleted == true;
        if (completed) {
          context.push('/loan/${widget.lan}/disbursal');
        } else {
          setState(() {
            _errorMessage = 'Loan agreement e-Sign is pending. Complete signature and retry.';
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
    final isCompleted = workflow?.esignCompleted == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agreement e-Sign'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Digital Agreement e-Sign',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'e-Sign loan agreement and sanction documents via Aadhaar OTP.',
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
                          const Text('e-Sign Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          AppStatusBadge(status: isCompleted ? 'COMPLETED' : 'PENDING'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Documents to Sign', 'Sanction Letter, Loan Agreement'),
                      _row('Authentication Method', 'Aadhaar e-Sign OTP'),
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
                  text: 'Request Loan Disbursal',
                  onPressed: () => context.push('/loan/${widget.lan}/disbursal'),
                  icon: Icons.arrow_forward_rounded,
                )
              else if (_isChecking)
                const AppLoader(message: 'Checking e-Sign status with NSDL/CDSL provider...')
              else ...[
                AppButton(
                  text: 'Initiate Agreement e-Sign',
                  isLoading: _isInitiating,
                  onPressed: _initiateEsign,
                  icon: Icons.draw_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Verify e-Sign Completion',
                  isOutlined: true,
                  onPressed: _checkEsignStatus,
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
