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

class EsignScreen extends ConsumerStatefulWidget {
  final String lan;

  const EsignScreen({super.key, required this.lan});

  @override
  ConsumerState<EsignScreen> createState() => _EsignScreenState();
}

class _EsignScreenState extends ConsumerState<EsignScreen> {
  bool _isInitiating = false;
  bool _isChecking = false;
  bool _isWebViewLoading = false;
  String? _errorMessage;
  String? _esignUrl;
  WebViewController? _webViewController;

  /// Builds a properly configured WebViewController for the e-Sign portal.
  /// Same requirements as the mandate WebView (UA, JS, error handling).
  WebViewController _buildWebViewController(String url) {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[EsignWebView] Loading: $url');
            if (mounted) setState(() => _isWebViewLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('[EsignWebView] Finished: $url');
            if (mounted) setState(() => _isWebViewLoading = false);

            // Detect e-sign provider callback / return URLs
            if (url.contains('esign-return') ||
                url.contains('pldirect') ||
                url.contains('callback') ||
                url.contains('success')) {
              _checkEsignStatus();
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              '[EsignWebView] Error ${error.errorCode}: '
              '${error.description} @ ${error.url}',
            );
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
              if (scheme == 'https' || scheme == 'http') {
                return NavigationDecision.navigate;
              }
              debugPrint('[EsignWebView] Blocked deep link: ${request.url}');
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

      // API: { success, data: { success, message, nextStep, loan: { esignCompleted } } }
      final outer = res['data'] ?? res;

      // Case 1: Backend immediately marks e-sign as completed (UAT/stub mode)
      final loanData = outer['loan'] as Map<String, dynamic>?;
      final isImmediatelyCompleted =
          loanData?['esignCompleted'] == true ||
          outer['nextStep'] == 'READY_FOR_DISBURSAL';

      if (isImmediatelyCompleted) {
        // Sync journey state and show success
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        if (mounted) {
          setState(() {}); // triggers rebuild — isCompleted will be true now
        }
        return;
      }

      // Case 2: Backend returns a URL for the e-sign portal (production flow)
      final inner = outer['data'] ?? outer;
      final esignUrl =
          inner['esignUrl'] ?? inner['url'] ?? outer['esignUrl'] ?? outer['url'];

      debugPrint('[Esign] Portal URL resolved: $esignUrl');

      if (esignUrl != null && esignUrl.toString().isNotEmpty) {
        final url = esignUrl.toString();
        final controller = _buildWebViewController(url);
        if (mounted) {
          setState(() {
            _esignUrl = url;
            _webViewController = controller;
            _isWebViewLoading = true;
          });
        }
      } else {
        // No URL returned and not immediately completed — unexpected
        setState(() {
          _errorMessage =
              'e-Sign portal URL could not be resolved. Please try again.';
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
        final completed = ref
                .read(journeyControllerProvider)
                .postApproval
                ?.workflow
                .esignCompleted ==
            true;
        if (completed) {
          setState(() {
            _esignUrl = null;
            _webViewController = null;
          });
          context.push('/loan/${widget.lan}/disbursal');
        } else {
          setState(() {
            _errorMessage =
                'Loan agreement e-Sign is pending. Complete the signature and retry.';
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
    final workflow =
        ref.watch(journeyControllerProvider).postApproval?.workflow;
    final isCompleted = workflow?.esignCompleted == true;

    // ── WebView Screen (production e-sign portal) ─────────────────────────
    if (_esignUrl != null && _webViewController != null && !isCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Agreement e-Sign'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _esignUrl = null;
                _webViewController = null;
                _isWebViewLoading = false;
                _errorMessage = null;
              });
            },
          ),
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
                tooltip: 'Check e-Sign status',
                onPressed: _checkEsignStatus,
              ),
          ],
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController!),

            if (_isWebViewLoading)
              Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading e-Sign portal…',
                      style: TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
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

    // ── Setup / Completed Screen ──────────────────────────────────────────
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Digitally sign your sanction letter and loan agreement to complete the process.',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 24),

              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'e-Sign Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          AppStatusBadge(
                              status: isCompleted ? 'COMPLETED' : 'PENDING'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Documents', 'Sanction Letter, Loan Agreement'),
                      _row('Method', 'Aadhaar OTP e-Sign'),
                    ],
                  ),
                ),
              ),

              // Success banner when e-sign is done
              if (isCompleted) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successGreen, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.successGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'e-Sign Completed!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successDarkGreen,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your loan agreement has been digitally signed. '
                              'You can now request disbursal.',
                              style: TextStyle(
                                color: AppTheme.successDarkGreen,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_errorMessage != null && !isCompleted) ...[
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
                  text: 'Request Loan Disbursal',
                  onPressed: () =>
                      context.push('/loan/${widget.lan}/disbursal'),
                  icon: Icons.account_balance_wallet_rounded,
                )
              else if (_isChecking)
                const AppLoader(
                    message: 'Checking e-Sign status with provider...')
              else if (_isInitiating)
                const AppLoader(message: 'Initiating e-Sign process...')
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
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textDarkSecondary),
          ),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
