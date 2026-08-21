import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/env.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class EsignScreen extends ConsumerStatefulWidget {
  final String lan;

  const EsignScreen({super.key, required this.lan});

  @override
  ConsumerState<EsignScreen> createState() => _EsignScreenState();
}

class _EsignScreenState extends ConsumerState<EsignScreen> {
  bool _documentViewed = false;
  bool _consent = false;
  bool _isLoading = false;
  bool _isCheckingStatus = true;

  // OTP flow state
  bool _otpSent = false;
  String _otpSessionId = '';
  String _maskedMobile = '';
  final TextEditingController _otpController = TextEditingController();

  // Timers
  int _expiresTimer = 0;
  int _resendTimer = 0;
  Timer? _countdownTimer;

  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer(int expiresInSeconds, int resendAfterSeconds) {
    _countdownTimer?.cancel();
    setState(() {
      _expiresTimer = expiresInSeconds;
      _resendTimer = resendAfterSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_expiresTimer > 0) _expiresTimer--;
        if (_resendTimer > 0) _resendTimer--;
        if (_expiresTimer == 0 && _resendTimer == 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkInitialStatus() async {
    setState(() => _isCheckingStatus = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/customer/loans/${widget.lan}/electronic-sign/status');
      
      final data = res['data'] ?? res;
      final isCompleted = data['completed'] == true;

      if (isCompleted) {
        setState(() {
          _consent = true;
        });
      }
    } catch (e) {
      debugPrint('[Esign] Error fetching status: $e');
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  void _showDocumentPreviewModal(String docUrl) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(docUrl));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Loan Agreement Document',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: WebViewWidget(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewDocument() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Mark document as viewed on backend
      await apiClient.post(
        '/customer/loans/${widget.lan}/electronic-sign/document/viewed',
        data: {},
      );

      // 2. Resolve token & construct document URL
      final storage = ref.read(secureStorageProvider);
      final token = await storage.getAuthToken();
      final baseUrl = currentEnvironment.apiBaseUrl;
      final docUrl = '$baseUrl/customer/loans/${widget.lan}/electronic-sign/document?token=${Uri.encodeComponent(token ?? '')}';

      final uri = Uri.parse(docUrl);

      // Launch URL directly (bypassing canLaunchUrl which fails on Android 11+)
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }

      // Also show in-app preview modal
      if (mounted) {
        _showDocumentPreviewModal(docUrl);
      }

      if (mounted) {
        setState(() {
          _documentViewed = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _documentViewed = true; // Still allow viewing state on error/stub
        });
      }
    }
  }

  Future<void> _sendOtp() async {
    if (!_documentViewed) {
      setState(() {
        _errorMessage = 'Please view the loan agreement document before requesting OTP.';
      });
      return;
    }
    if (!_consent) {
      setState(() {
        _errorMessage = 'Please check the consent box to proceed.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Prepare agreement
      await apiClient.post(
        '/customer/loans/${widget.lan}/electronic-sign/prepare',
        data: {},
      );

      // 2. Send OTP with consent
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/electronic-sign/otp/send',
        data: {'consentAccepted': true},
      );

      final data = res['data'] ?? res;

      final sessionId = data['otpSessionId']?.toString() ?? '';
      final mobile = data['maskedMobile']?.toString() ?? '';
      final expires = (data['expiresInSeconds'] ?? 300) as int;
      final resend = (data['resendAfterSeconds'] ?? 60) as int;

      if (mounted) {
        setState(() {
          _otpSessionId = sessionId;
          _maskedMobile = mobile;
          _otpSent = true;
          _statusMessage = 'OTP sent to your verified mobile number ($mobile).';
        });
        _startTimer(expires, resend);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException) {
          final apiClient = ref.read(apiClientProvider);
          msg = apiClient.handleError(e).message;
        } else if (e is AppException) {
          msg = e.message;
        } else if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      // Verify OTP (backend automatically captures IP address, User-Agent, headers)
      await apiClient.post(
        '/customer/loans/${widget.lan}/electronic-sign/otp/verify',
        data: {
          'otpSessionId': _otpSessionId,
          'otp': otp,
        },
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        setState(() {
          _statusMessage = 'Agreement Electronically Accepted Successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan Agreement Electronically Accepted Successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        context.push('/loan/${widget.lan}/disbursal');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException) {
          final apiClient = ref.read(apiClientProvider);
          msg = apiClient.handleError(e).message;
        } else if (e is AppException) {
          msg = e.message;
        } else if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadDocument(String endpoint) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.getAuthToken();
      final baseUrl = currentEnvironment.apiBaseUrl;
      final downloadUrl = '$baseUrl/customer/loans/${widget.lan}/electronic-sign/$endpoint?token=${Uri.encodeComponent(token ?? '')}';

      final uri = Uri.parse(downloadUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(journeyControllerProvider).postApproval?.workflow;
    final isCompleted = workflow?.esignCompleted == true;

    if (_isCheckingStatus) {
      return Scaffold(
        appBar: const AppHeader(title: 'e-Sign Loan Agreement'),
        body: const AppLoader(message: 'Checking agreement e-Sign status...'),
      );
    }

    return Scaffold(
      appBar: AppHeader(
        title: 'e-Sign Loan Agreement',
        fallbackRoute: widget.lan.isNotEmpty ? '/loan/${widget.lan}/mandate' : '/dashboard',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Digital Agreement e-Sign',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Electronically accept your loan agreement using mobile OTP authentication.',
                style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 24),

              if (isCompleted) ...[
                // Completed State View
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.successGreen, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Loan Agreement Electronically Accepted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successDarkGreen,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agreement electronically accepted via OTP authentication and stamped with legal audit evidence.',
                        style: TextStyle(color: AppTheme.successDarkGreen, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Download Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadDocument('accepted-document'),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Accepted Agreement', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadDocument('audit-certificate'),
                        icon: const Icon(Icons.verified_user_rounded, size: 18),
                        label: const Text('Audit Certificate', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Proceed to Disbursal',
                  onPressed: () => context.push('/loan/${widget.lan}/disbursal'),
                  icon: Icons.arrow_forward_rounded,
                ),
              ] else ...[
                // Uncompleted State View
                // Step 1: Document View Action
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Electronic Agreement Acceptance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please preview your complete loan agreement. Once viewed, check the consent box and enter the OTP sent to your registered mobile number to execute acceptance.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary),
                        ),
                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _viewDocument,
                              icon: const Icon(Icons.visibility_rounded, size: 18),
                              label: const Text('View Agreement Document'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryTeal,
                                side: const BorderSide(color: AppTheme.primaryTeal),
                                minimumSize: const Size(0, 44),
                              ),
                            ),
                            if (_documentViewed)
                              const AppStatusBadge(
                                status: 'VERIFIED',
                                label: 'Document Viewed',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Step 2: Consent Checkbox
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _consent,
                          activeColor: AppTheme.primaryTeal,
                          onChanged: _documentViewed
                              ? (val) => setState(() => _consent = val ?? false)
                              : null,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _documentViewed
                                ? () => setState(() => _consent = !_consent)
                                : null,
                            child: const Text(
                              'I confirm that I have read and understood the Personal Loan Agreement. I consent to execute and accept this agreement electronically using the OTP sent to my verified mobile number. I acknowledge that my authenticated session, document hash, timestamp, IP address and device information will be recorded as evidence of this acceptance.',
                              style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textDarkSecondary),
                            ),
                          ),
                        ),
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
                      border: Border.all(color: AppTheme.errorRed, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_statusMessage != null && _errorMessage == null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successGreen, width: 1),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: const TextStyle(color: AppTheme.successDarkGreen, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Step 3: OTP Send / Verify Controls
                if (!_otpSent) ...[
                  AppButton(
                    text: 'Send OTP for e-Sign',
                    isLoading: _isLoading,
                    onPressed: (_documentViewed && _consent) ? _sendOtp : null,
                    icon: Icons.send_rounded,
                  ),
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter 6-Digit OTP sent to $_maskedMobile',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: '• • • • • •',
                              counterText: '',
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _expiresTimer > 0
                                    ? 'Expires in ${(_expiresTimer ~/ 60)}:${(_expiresTimer % 60).toString().padLeft(2, '0')}'
                                    : 'OTP Expired',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                              ),
                              TextButton(
                                onPressed: (_resendTimer == 0 && !_isLoading) ? _sendOtp : null,
                                child: Text(
                                  _resendTimer > 0 ? 'Resend in ${_resendTimer}s' : 'Resend OTP',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppButton(
                    text: 'Verify OTP & Accept Agreement',
                    isLoading: _isLoading,
                    onPressed: _verifyOtp,
                    icon: Icons.verified_rounded,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
