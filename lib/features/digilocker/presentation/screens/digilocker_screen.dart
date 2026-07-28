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

class DigilockerScreen extends ConsumerStatefulWidget {
  final String lan;

  const DigilockerScreen({super.key, required this.lan});

  @override
  ConsumerState<DigilockerScreen> createState() => _DigilockerScreenState();
}

class _DigilockerScreenState extends ConsumerState<DigilockerScreen> {
  bool _isInitiating = false;
  bool _isFetching = false;
  String? _errorMessage;

  void _initiateDigilocker() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/digilocker/initiate',
        data: {'customerId': customerId},
      );

      final data = res['data'] ?? res;
      final redirectUrl = data['redirectUrl'] ?? data['url'];

      if (redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
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

  void _fetchDigilockerDetails() async {
    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isFetching = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/loans/${widget.lan}/digilocker/fetch-details',
        data: {'customerId': customerId},
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        final status = ref.read(journeyControllerProvider).postApproval?.digilocker.status;
        if (status == 'VERIFIED') {
          context.push('/loan/${widget.lan}/address');
        } else {
          setState(() {
            _errorMessage = 'DigiLocker status is pending or not complete. Please retry after completing verification.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digilocker = ref.watch(journeyControllerProvider).postApproval?.digilocker;
    final isVerified = digilocker?.status == 'VERIFIED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiLocker Aadhaar KYC'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Aadhaar KYC Verification',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Verify your identity securely using DigiLocker Aadhaar integration.',
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
                          const Text('DigiLocker Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          AppStatusBadge(status: digilocker?.status ?? 'NOT_STARTED'),
                        ],
                      ),
                      if (isVerified) ...[
                        const Divider(height: 20),
                        _row('Masked Aadhaar', digilocker?.maskedAadhaar ?? 'XXXX-XXXX-1234'),
                        _row('Verified At', digilocker?.verifiedAt ?? 'Just now'),
                      ],
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
              const SizedBox(height: 32),
              if (isVerified)
                AppButton(
                  text: 'Confirm Aadhaar Address',
                  onPressed: () => context.push('/loan/${widget.lan}/address'),
                  icon: Icons.arrow_forward_rounded,
                )
              else if (_isFetching)
                const AppLoader(message: 'Fetching verified Aadhaar details...')
              else ...[
                AppButton(
                  text: 'Initiate DigiLocker Verification',
                  isLoading: _isInitiating,
                  onPressed: _initiateDigilocker,
                  icon: Icons.security_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Fetch & Verify Completed KYC',
                  isOutlined: true,
                  onPressed: _fetchDigilockerDetails,
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
