import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class DigilockerScreen extends ConsumerStatefulWidget {
  final String? lan;

  const DigilockerScreen({super.key, this.lan});

  @override
  ConsumerState<DigilockerScreen> createState() => _DigilockerScreenState();
}

class _DigilockerScreenState extends ConsumerState<DigilockerScreen> {
  bool _isInitiating = false;
  bool _isFetching = false;
  bool _isVerified = false;
  String? _errorMessage;
  String? _verificationUrl;
  WebViewController? _webViewController;

  void _initiateDigilocker() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    final isOnboarding = widget.lan == null || widget.lan!.isEmpty;

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final String initiateUrl;
      final Map<String, dynamic> body;

      if (isOnboarding) {
        initiateUrl = '/customer/aadhaar-kyc/digilocker/initiate';
        body = {'consentGiven': true};
      } else {
        final effectiveLan = widget.lan?.isNotEmpty == true
            ? widget.lan
            : customer.latestLan;
        if (effectiveLan == null || effectiveLan.isEmpty) {
          setState(() {
            _errorMessage = 'Loan account LAN is missing.';
          });
          return;
        }
        initiateUrl = '/customer/loans/$effectiveLan/digilocker/initiate';
        body = {'customerId': customer.id};
      }

      final res = await apiClient.post(initiateUrl, data: body);
      
      Map<String, dynamic> innerData = {};
      if (res['data'] is Map) {
        final d1 = res['data'];
        if (d1['data'] is Map) {
          innerData = Map<String, dynamic>.from(d1['data']);
        } else {
          innerData = Map<String, dynamic>.from(d1);
        }
      } else {
        innerData = Map<String, dynamic>.from(res);
      }

      final redirectUrl = innerData['verificationUrl'] ?? innerData['redirectUrl'] ?? innerData['url'];

      if (redirectUrl != null) {
        setState(() {
          _verificationUrl = redirectUrl;
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (url) {
                  if (url.contains('callback') || url.contains('success') || url.contains('webhook')) {
                    _fetchDigilockerDetails();
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse(_verificationUrl!));
        });
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
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    setState(() {
      _isFetching = true;
      _errorMessage = null;
    });

    final isOnboarding = widget.lan == null || widget.lan!.isEmpty;

    try {
      final apiClient = ref.read(apiClientProvider);

      if (isOnboarding) {
        final res = await apiClient.get('/customer/aadhaar-kyc/digilocker/status');
        
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        
        final updatedCustomer = ref.read(journeyControllerProvider).customer;
        final data = res['data'] ?? res;
        final isKycDone = updatedCustomer?.aadhaarVerified == true || 
                          updatedCustomer?.aadhaarKycStatus == 'VERIFIED' || 
                          data['aadhaarVerified'] == true || 
                          data['status'] == 'VERIFIED';

        if (isKycDone && mounted) {
          setState(() {
            _isVerified = true;
            _verificationUrl = null;
            _webViewController = null;
          });
          context.push('/onboarding/address');
        } else {
          setState(() {
            _errorMessage = 'DigiLocker status is pending or not complete. Please retry after completing verification.';
          });
        }
      } else {
        final effectiveLan = widget.lan?.isNotEmpty == true
            ? widget.lan
            : customer.latestLan;
        if (effectiveLan == null || effectiveLan.isEmpty) {
          setState(() {
            _errorMessage = 'Loan account not available. Please complete application first.';
          });
          return;
        }

        final res = await apiClient.post(
          '/customer/loans/$effectiveLan/digilocker/fetch-details',
          data: {'customerId': customer.id},
        );

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();

        if (mounted) {
          final data = res['data'] ?? res;
          final status = data['status'] as String?;
          if (status == 'VERIFIED') {
            setState(() {
              _isVerified = true;
              _verificationUrl = null;
              _webViewController = null;
            });
            context.push('/onboarding/address');
          } else {
            setState(() {
              _errorMessage = 'DigiLocker status is pending or not complete. Please retry after completing verification.';
            });
          }
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
    final customer = ref.watch(journeyControllerProvider).customer;
    final digilocker = ref.watch(journeyControllerProvider).postApproval?.digilocker;
    
    final isOnboarding = widget.lan == null || widget.lan!.isEmpty;

    final isVerified = _isVerified || 
                       (isOnboarding 
                           ? (customer?.aadhaarVerified == true || customer?.aadhaarKycStatus == 'VERIFIED')
                           : digilocker?.status == 'VERIFIED');

    if (_verificationUrl != null && !isVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('DigiLocker Verification'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _verificationUrl = null;
                _webViewController = null;
              });
            },
          ),
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    final statusString = isOnboarding 
        ? (customer?.aadhaarKycStatus ?? 'NOT_STARTED') 
        : (digilocker?.status ?? 'NOT_STARTED');

    final maskedAadhaarString = isOnboarding 
        ? (customer?.maskedAadhaar ?? 'XXXX-XXXX-XXXX') 
        : (digilocker?.maskedAadhaar ?? 'XXXX-XXXX-1234');

    final verifiedAtString = isOnboarding 
        ? (customer?.aadhaarVerifiedAt ?? 'Just now') 
        : (digilocker?.verifiedAt ?? 'Just now');

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
                          AppStatusBadge(status: statusString),
                        ],
                      ),
                      if (isVerified) ...[
                        const Divider(height: 20),
                        _row('Masked Aadhaar', maskedAadhaarString),
                        _row('Verified At', verifiedAtString),
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
                  onPressed: () => context.push('/onboarding/address'),
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
