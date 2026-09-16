import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
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
  bool _isWebViewLoading = false;
  String? _errorMessage;
  String? _mandateUrl;
  WebViewController? _webViewController;

  String _convertIntentToUri(String url) {
    if (!url.startsWith('intent://')) return url;

    final intentIndex = url.indexOf('#Intent;');
    String pathAndQuery = '';
    String fragment = '';

    if (intentIndex != -1) {
      pathAndQuery = url.substring('intent://'.length, intentIndex);
      fragment = url.substring(intentIndex);
    } else {
      pathAndQuery = url.substring('intent://'.length);
    }

    String scheme = 'upi';
    final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(fragment);
    if (schemeMatch != null && schemeMatch.group(1) != null && schemeMatch.group(1)!.isNotEmpty) {
      scheme = schemeMatch.group(1)!;
    }

    return '$scheme://$pathAndQuery';
  }

  Future<void> _launchExternalAppUrl(String originalUrl) async {
    try {
      final targetUrl = _convertIntentToUri(originalUrl);
      debugPrint('[MandateWebView] Intercepted deep link URL: $originalUrl -> Launching: $targetUrl');
      final uri = Uri.parse(targetUrl);

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('[MandateWebView] External application launch failed: $e');
      }

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
        } catch (e) {
          debugPrint('[MandateWebView] ExternalNonBrowser launch failed: $e');
        }
      }

      if (!launched && originalUrl != targetUrl) {
        try {
          final origUri = Uri.parse(originalUrl);
          launched = await launchUrl(origUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not launch UPI app. Please ensure a UPI app (Google Pay, PhonePe, Paytm) is installed.',
            ),
            backgroundColor: AppTheme.warningOrange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MandateWebView] Error launching deep link: $e');
    }
  }

  /// Builds a fully-configured WebViewController for the Easebuzz payment portal.
  ///
  /// Why each setting matters:
  ///  - setUserAgent: Easebuzz detects the default Android WebView UA and may
  ///    redirect or block it. A Chrome mobile UA bypasses this.
  ///  - setJavaScriptMode(unrestricted): The payment page is a JS SPA.
  ///  - DOM storage (via platform config): Easebuzz stores session/state in localStorage.
  ///  - onNavigationRequest: UPI deep links (upi://, phonepe://, etc.) launch the UPI app directly.
  ///  - onWebResourceError: Only surface main-frame failures; sub-resource errors
  ///    (fonts, analytics, etc.) are expected and should not block the user.
  WebViewController _buildWebViewController(String url) {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

      // Use a standard Chrome mobile UA
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )

      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[MandateWebView] Loading: $url');
            if (mounted) setState(() => _isWebViewLoading = true);
          },

          onPageFinished: (url) {
            debugPrint('[MandateWebView] Finished: $url');
            if (mounted) setState(() => _isWebViewLoading = false);

            // Auto-detect Easebuzz callback / deep-link return URLs
            if (url.contains('callback') ||
                url.contains('success') ||
                url.contains('result') ||
                url.contains('mandate-return') ||
                url.contains('pldirect')) {
              _checkMandateStatus();
            }
          },

          onWebResourceError: (error) {
            debugPrint(
              '[MandateWebView] Error ${error.errorCode}: '
              '${error.description} @ ${error.url}',
            );
            if (error.errorCode == -10 || error.description.contains('ERR_UNKNOWN_URL_SCHEME')) {
              return;
            }
            // Only report main-frame errors — sub-resource errors are normal
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isWebViewLoading = false;
                _errorMessage =
                    'Page failed to load (${error.errorCode}): '
                    '${error.description}. '
                    'Please check your internet connection and try again.';
              });
            }
          },

          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null) {
              final scheme = uri.scheme.toLowerCase();
              if (scheme == 'https' || scheme == 'http' || scheme == 'about' || scheme == 'data') {
                return NavigationDecision.navigate;
              }
              debugPrint('[MandateWebView] Intercepted deep link: ${request.url}');
              _launchExternalAppUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )

      ..loadRequest(
        Uri.parse(url),
        headers: const {
          'Accept':
              'text/html,application/xhtml+xml,application/xml;'
              'q=0.9,image/webp,*/*;q=0.8',
        },
      );

    return controller;
  }

  void _initiateMandate(String mandateType) async {
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
        data: {
          'customerId': customerId,
          'mandateType': mandateType,
        },
      );

      // API: { success, data: { success, message, data: { portalUrl, ... } } }
      final outer = res['data'] ?? res;
      final inner = outer['data'] ?? outer;
      final mandateUrl =
          inner['portalUrl'] ?? inner['mandateUrl'] ?? inner['url'];

      debugPrint('[Mandate] Portal URL resolved: $mandateUrl');

      if (mandateUrl != null && mandateUrl.toString().isNotEmpty) {
        final url = mandateUrl.toString();
        // Build controller BEFORE setState to avoid a stale-url race
        final controller = _buildWebViewController(url);
        if (mounted) {
          setState(() {
            _mandateUrl = url;
            _webViewController = controller;
            _isWebViewLoading = true;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Mandate portal URL could not be resolved. Please try again.';
        });
      }
    } catch (e) {
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
        final completed = ref
                .read(journeyControllerProvider)
                .postApproval
                ?.workflow
                .mandateCompleted ==
            true;
        if (completed) {
          setState(() {
            _mandateUrl = null;
            _webViewController = null;
          });
          context.push('/loan/${widget.lan}/esign');
        } else {
          setState(() {
            _errorMessage =
                'Mandate registration is pending. Complete registration '
                'in the bank page and retry.';
          });
        }
      }
    } catch (e) {
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
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow =
        ref.watch(journeyControllerProvider).postApproval?.workflow;
    final isCompleted = workflow?.mandateCompleted == true;

    final tr = ref.watch(appLocalizationsProvider);

    // ── WebView Screen ────────────────────────────────────────────────────
    if (_mandateUrl != null && _webViewController != null && !isCompleted) {
      return Scaffold(
        appBar: AppHeader(
          title: tr.tr('mandate_title'),
          onBackPressed: () {
            setState(() {
              _mandateUrl = null;
              _webViewController = null;
              _isWebViewLoading = false;
              _errorMessage = null;
            });
          },
          actions: [
            if (_isChecking)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Check mandate status',
                onPressed: _checkMandateStatus,
              ),
          ],
        ),
        body: Stack(
          children: [
            // Easebuzz payment portal
            WebViewWidget(controller: _webViewController!),

            // Full-screen white overlay while the portal is rendering
            if (_isWebViewLoading)
              Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment portal…',
                      style: TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Please wait, do not press back.',
                      style: TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom error banner — only for main-frame failures
            if (_errorMessage != null && !_isWebViewLoading)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: AppTheme.errorBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ── Setup Screen ──────────────────────────────────────────────────────
    return Scaffold(
      appBar: AppHeader(
        title: 'Mandate Setup',
        fallbackRoute: widget.lan.isNotEmpty ? '/loan/${widget.lan}/kfs' : '/dashboard',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Auto-Debit Mandate Setup',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register automated repayment mandate with your bank '
                'for hassle-free EMI repayments.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textDarkSecondary),
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
                          const Text(
                            'Mandate Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          AppStatusBadge(
                              status: isCompleted ? 'COMPLETED' : 'PENDING'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Mandate Type', 'UPI Autopay / NetBanking AutoDebit'),
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
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                        color: AppTheme.errorRed, fontSize: 13),
                  ),
                ),
              ],
              const Spacer(),
              if (isCompleted)
                AppButton(
                  text: 'Proceed to Agreement e-Sign',
                  onPressed: () =>
                      context.push('/loan/${widget.lan}/esign'),
                  icon: Icons.arrow_forward_rounded,
                )
              else if (_isChecking)
                const AppLoader(
                    message: 'Checking mandate status with bank gateway...')
              else ...[
                AppButton(
                  text: 'Set Up via Netbanking / Debit Card',
                  isLoading: _isInitiating,
                  onPressed: () => _initiateMandate('ENACH'),
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Set Up via UPI Autopay',
                  isLoading: _isInitiating,
                  isOutlined: true,
                  onPressed: () => _initiateMandate('UPI'),
                  icon: Icons.qr_code_rounded,
                ),
                const SizedBox(height: 16),
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
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textDarkSecondary),
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
