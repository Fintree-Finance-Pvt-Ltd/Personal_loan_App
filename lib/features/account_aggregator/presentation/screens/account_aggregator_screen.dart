import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class AccountAggregatorScreen extends ConsumerStatefulWidget {
  final String? lan;

  const AccountAggregatorScreen({super.key, this.lan});

  @override
  ConsumerState<AccountAggregatorScreen> createState() => _AccountAggregatorScreenState();
}

class _AccountAggregatorScreenState extends ConsumerState<AccountAggregatorScreen> {
  bool _isInitiating = false;
  bool _isWebViewActive = false;
  String? _sdkUrl;
  WebViewController? _webViewController;

  String _status = 'NOT_STARTED'; // NOT_STARTED, INITIATED, SDK_OPENED, CONSENT_PENDING, CONSENT_APPROVED, DATA_PENDING, SUCCESS, FAILED, EXPIRED, CANCELLED
  String? _consentStatus;
  String? _dataStatus;
  String? _failureReason;
  Map<String, dynamic>? _bankSummary;
  bool _isCompleted = false;

  Timer? _pollTimer;
  DateTime? _pollStartTime;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchStatus());
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  String get _effectiveLan {
    if (widget.lan != null && widget.lan!.isNotEmpty) return widget.lan!;
    final journeyState = ref.read(journeyControllerProvider);
    return journeyState.customer?.latestLan ?? journeyState.customer?.platformLan ?? '';
  }

  bool get _isOnboarding => widget.lan == null || widget.lan!.isEmpty;

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollStartTime = DateTime.now();

    _fetchStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pollStartTime != null && DateTime.now().difference(_pollStartTime!).inMinutes > 10) {
        _stopPolling();
        return;
      }
      _fetchStatus();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchStatus() async {
    print('[AA SCREEN] [CALL] _fetchStatus for LAN: $_effectiveLan');
    try {
      final customerApi = ref.read(customerApiProvider);
      final res = await customerApi.getAccountAggregatorStatus(_effectiveLan);
      print('[AA SCREEN] [RESPONSE] _fetchStatus response: $res');

      if (!mounted) return;

      final dataMap = (res['data'] is Map<String, dynamic>)
          ? res['data'] as Map<String, dynamic>
          : res;

      final currentStatus = (dataMap['status'] ?? res['status'] ?? 'NOT_STARTED').toString();
      final consentStatus = (dataMap['consentStatus'] ?? res['consentStatus'])?.toString();
      final dataStatus = (dataMap['dataStatus'] ?? res['dataStatus'])?.toString();
      final failureReason = (dataMap['failureReason'] ?? res['failureReason'])?.toString();

      final isDone = dataMap['completed'] == true ||
          res['completed'] == true ||
          dataMap['isDone'] == true ||
          res['isDone'] == true ||
          ['SUCCESS', 'COMPLETED', 'APPROVED', 'VERIFIED'].contains(currentStatus.toUpperCase()) ||
          ['COMPLETED', 'FETCHED', 'SUCCESS', 'DELIVERED'].contains(dataStatus?.toUpperCase());

      final summary = (dataMap['bankSummary'] ?? res['bankSummary']) is Map<String, dynamic>
          ? (dataMap['bankSummary'] ?? res['bankSummary']) as Map<String, dynamic>
          : null;

      setState(() {
        _status = currentStatus;
        _consentStatus = consentStatus;
        _dataStatus = dataStatus;
        _failureReason = failureReason;
        _bankSummary = summary;
        _isCompleted = isDone;
      });

      if (isDone) {
        _stopPolling();
        if (_isWebViewActive) {
          setState(() {
            _isWebViewActive = false;
          });
        }
        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      } else if (['FAILED', 'EXPIRED', 'CANCELLED'].contains(currentStatus.toUpperCase())) {
        _stopPolling();
      }
    } catch (e) {
      print('[AA SCREEN] [ERROR] Failed to fetch AA status: $e');
    }
  }

  Future<void> _initiateAA() async {
    print('[AA SCREEN] [CALL] _initiateAA for LAN: $_effectiveLan');
    setState(() {
      _isInitiating = true;
      _failureReason = null;
    });

    try {
      final customerApi = ref.read(customerApiProvider);
      final res = await customerApi.initiateAccountAggregator(_effectiveLan);
      print('[AA SCREEN] [RESPONSE] _initiateAA response: $res');

      final url = res['sdkUrl']?.toString() ?? res['data']?['sdkUrl']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Failed to generate Unaport AA Web SDK URL.');
      }

      print('[AA SCREEN] Web SDK URL generated: $url');
      
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'UnaportAA',
          onMessageReceived: (JavaScriptMessage message) {
            print('[AA SCREEN] JS Message received from UnaportAA: ${message.message}');
            if (mounted) {
              setState(() {
                _isWebViewActive = false;
              });
              _fetchStatus();
            }
          },
        )
        ..addJavaScriptChannel(
          'FlutterBridge',
          onMessageReceived: (JavaScriptMessage message) {
            print('[AA SCREEN] JS Message received from FlutterBridge: ${message.message}');
            if (mounted) {
              setState(() {
                _isWebViewActive = false;
              });
              _fetchStatus();
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              print('[AA SCREEN] WebView navigating to: ${request.url}');
              final lowerUrl = request.url.toLowerCase();
              if (lowerUrl.contains('exit') ||
                  lowerUrl.contains('success') ||
                  lowerUrl.contains('callback') ||
                  lowerUrl.contains('completed') ||
                  lowerUrl.contains('done') ||
                  lowerUrl.contains('close')) {
                if (mounted) {
                  setState(() {
                    _isWebViewActive = false;
                  });
                  _fetchStatus();
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageFinished: (String url) {
              print('[AA SCREEN] WebView page finished loading: $url');
              final lowerUrl = url.toLowerCase();

              // Inject JavaScript listener to detect EXIT button click inside SDK WebView
              _webViewController?.runJavaScript('''
                (function() {
                  document.addEventListener('click', function(e) {
                    var el = e.target;
                    while (el && el !== document.body) {
                      var text = (el.innerText || el.textContent || '').trim().toUpperCase();
                      if (text === 'EXIT' || el.id === 'exit' || el.getAttribute('data-action') === 'exit') {
                        if (window.UnaportAA) window.UnaportAA.postMessage('EXIT_CLICKED');
                        if (window.FlutterBridge) window.FlutterBridge.postMessage('EXIT_CLICKED');
                        break;
                      }
                      el = el.parentElement;
                    }
                  }, true);
                })();
              ''');

              if (lowerUrl.contains('callback') ||
                  lowerUrl.contains('success') ||
                  lowerUrl.contains('webhook') ||
                  lowerUrl.contains('exit') ||
                  lowerUrl.contains('completed') ||
                  lowerUrl.contains('done')) {
                if (mounted) {
                  setState(() {
                    _isWebViewActive = false;
                  });
                  _fetchStatus();
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      setState(() {
        _sdkUrl = url;
        _webViewController = controller;
        _isWebViewActive = true;
        _status = 'SDK_OPENED';
        _isInitiating = false;
      });

      _startPolling();
    } catch (e) {
      print('[AA SCREEN] [ERROR] _initiateAA error: $e');
      if (!mounted) return;
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
        _isInitiating = false;
        _failureReason = msg;
        _status = 'FAILED';
      });
    }
  }

  Future<void> _handleRetry() async {
    print('[AA SCREEN] [CALL] _handleRetry for LAN: $_effectiveLan');
    try {
      final customerApi = ref.read(customerApiProvider);
      final res = await customerApi.refreshAccountAggregatorStatus(_effectiveLan);
      print('[AA SCREEN] [RESPONSE] refreshAccountAggregatorStatus response: $res');
    } catch (e) {
      print('[AA SCREEN] [ERROR] refreshAccountAggregatorStatus error: $e');
    }
    _initiateAA();
  }

  Future<void> _openExternalBrowser() async {
    if (_sdkUrl != null) {
      final uri = Uri.parse(_sdkUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _proceedNext() async {
    _stopPolling();
    await ref.read(journeyControllerProvider.notifier).syncCustomerState();
    if (!mounted) return;
    if (_isOnboarding) {
      context.push('/onboarding/review');
    } else {
      context.push('/loan/$_effectiveLan/bank');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWebViewActive && _webViewController != null) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Account Aggregator Portal',
          onBackPressed: () {
            setState(() {
              _isWebViewActive = false;
            });
            _fetchStatus();
          },
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isWebViewActive = false;
                });
                _fetchStatus();
              },
              tooltip: 'Exit SDK',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              onPressed: _openExternalBrowser,
              tooltip: 'Open in browser',
            ),
          ],
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const AppHeader(
        title: 'Account Aggregator',
        fallbackRoute: '/onboarding/address',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppStepper(
                currentStep: 7,
                totalSteps: 7,
                stepTitles: ['PAN Verification', 'Personal Details', 'Assessment Fee', 'Profile & Income', 'Photo & Liveness', 'DigiLocker KYC', 'Account Aggregator'],
              ),
              const SizedBox(height: 24),
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLightTeal,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: AppTheme.primaryTeal,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect Bank Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Account Aggregator Verification',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textDarkSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isCompleted || _status == 'SUCCESS')
                      const AppStatusBadge(status: 'VERIFIED'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Description Text
              const Text(
                'Share your bank statement information securely through RBI-regulated Account Aggregator to complete your loan eligibility assessment.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textDarkSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Security Compliance Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoftTeal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% Encrypted & RBI Consent Compliant. No net-banking passwords or credentials are stored.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textDarkPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Dynamic Status Body UI
              if (_isInitiating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: AppLoader(message: 'Generating secure bank portal link...'),
                  ),
                )
              else if (_isCompleted || _status == 'SUCCESS')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.successBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.successGreen,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bank Account Statement Verified',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDarkPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Bank statement data fetched successfully.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textDarkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppStatusBadge(status: 'SUCCESS'),
                        ],
                      ),

                      if (_bankSummary != null) ...[
                        const Divider(height: 28),
                        Text(
                          'BANK STATEMENT DETAILS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppTheme.textDarkSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                'Connected Bank',
                                '${_bankSummary!['fipName'] ?? 'Bank Account'} (${_bankSummary!['accountNumberMasked'] ?? 'XXXX'})',
                              ),
                              const SizedBox(height: 10),
                              _buildSummaryRow(
                                'Account Holder',
                                '${_bankSummary!['accountHolderName'] ?? 'Primary Account'}',
                              ),
                              const SizedBox(height: 10),
                              _buildSummaryRow(
                                'Current Balance',
                                CurrencyUtils.formatAmount(_bankSummary!['currentBalance'], showDecimals: true),
                                isBold: true,
                              ),
                              const SizedBox(height: 10),
                              _buildSummaryRow(
                                'Average Bank Balance (ABB)',
                                CurrencyUtils.formatAmount(
                                  _bankSummary!['abb'] ?? _bankSummary!['averageBalance'],
                                  showDecimals: true,
                                ),
                                isBold: true,
                                valueColor: AppTheme.primaryTeal,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Proceed to Review Application',
                        onPressed: _proceedNext,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                )
              else if (['INITIATED', 'SDK_OPENED', 'CONSENT_PENDING', 'CONSENT_APPROVED', 'DATA_PENDING'].contains(_status))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.infoBlue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _status == 'CONSENT_APPROVED' || _status == 'DATA_PENDING'
                            ? 'Fetching & Analyzing Bank Statement Data'
                            : 'Bank Connection In Progress',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _status == 'CONSENT_APPROVED' || _status == 'DATA_PENDING'
                            ? 'Consent approved! Retrieving and validating your bank account information...'
                            : 'Complete bank selection and OTP authorization in the secure window.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDarkSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_sdkUrl != null)
                        AppButton(
                          text: 'Re-open Bank Consent Portal',
                          onPressed: () {
                            setState(() {
                              _isWebViewActive = true;
                            });
                          },
                          icon: Icons.open_in_new_rounded,
                        ),
                    ],
                  ),
                )
              else if (['FAILED', 'CANCELLED', 'EXPIRED'].contains(_status))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.errorRed,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status == 'EXPIRED' ? 'Consent Session Expired' : 'Bank Connection Failed',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _failureReason ??
                            (_status == 'EXPIRED'
                                ? 'The bank consent session expired before completion. Please try connecting again.'
                                : 'Unable to complete bank statement verification. Please retry.'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textDarkSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        text: 'Retry Bank Connection',
                        onPressed: _handleRetry,
                        icon: Icons.refresh_rounded,
                      ),
                    ],
                  ),
                )
              else
                AppButton(
                  text: 'Connect Bank Account',
                  onPressed: _initiateAA,
                  icon: Icons.account_balance_rounded,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textDarkSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppTheme.textDarkPrimary,
          ),
        ),
      ],
    );
  }
}
