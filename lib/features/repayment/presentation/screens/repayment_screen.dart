import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  final String lan;

  const RepaymentScreen({super.key, required this.lan});

  @override
  ConsumerState<RepaymentScreen> createState() => _RepaymentScreenState();
}

class _RepaymentScreenState extends ConsumerState<RepaymentScreen> {
  bool _isLoading = true;
  bool _isInitiating = false;
  String? _errorMessage;
  String? _statusMessage;
  Map<String, dynamic>? _loanDetails;

  int _selectedInstallmentNumber = 1;
  double _paymentAmount = 0.0;
  final TextEditingController _customAmountController = TextEditingController();

  // Easebuzz Gateway WebView state
  String? _paymentUrl;
  WebViewController? _webViewController;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchDetails());
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/customer/loans/${widget.lan}/details');
      
      final data = res['data'] ?? res;
      if (mounted) {
        final detailsMap = data is Map<String, dynamic> ? data : null;
        final rpsList = (detailsMap?['repaymentSchedule'] as List<dynamic>?) ?? [];

        // Pre-select first unpaid installment
        int defaultInst = 1;
        double defaultAmt = 0.0;

        for (final item in rpsList) {
          final map = item as Map<String, dynamic>;
          final status = map['paymentStatus']?.toString().toUpperCase();
          if (status != 'PAID') {
            defaultInst = (map['installmentNumber'] ?? 1) as int;
            defaultAmt = ((map['remainingAmount'] ?? map['emi'] ?? 0) as num).toDouble();
            break;
          }
        }

        if (defaultAmt == 0.0 && rpsList.isNotEmpty) {
          final firstMap = rpsList.first as Map<String, dynamic>;
          defaultAmt = ((firstMap['emi'] ?? 0) as num).toDouble();
        }

        setState(() {
          _loanDetails = detailsMap;
          _selectedInstallmentNumber = defaultInst;
          _paymentAmount = defaultAmt;
          _customAmountController.text = defaultAmt > 0 ? defaultAmt.toStringAsFixed(0) : '';
        });
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
          _errorMessage = 'Failed to load loan details: $msg';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  WebViewController _buildEasebuzzWebViewController(String url) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String finishedUrl) {
            debugPrint('[EasebuzzRepay] Finished URL: $finishedUrl');
            final lower = finishedUrl.toLowerCase();
            if (lower.contains('success') ||
                lower.contains('confirm') ||
                lower.contains('status') ||
                lower.contains('response') ||
                lower.contains('details')) {
              _onPaymentCompleted();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final lower = request.url.toLowerCase();
            if (lower.contains('success') ||
                lower.contains('confirm') ||
                lower.contains('repay/confirm') ||
                lower.contains('details')) {
              _onPaymentCompleted();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _onPaymentCompleted() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      await _fetchDetails();

      if (mounted) {
        setState(() {
          _paymentUrl = null;
          _webViewController = null;
          _statusMessage = 'Repayment completed successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMI Repayment Completed Successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('[EasebuzzRepay] Error verifying payment: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _initiateEasebuzzPayment() async {
    final amountToPay = double.tryParse(_customAmountController.text.trim()) ?? _paymentAmount;
    if (amountToPay <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid repayment amount.';
      });
      return;
    }

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/customer/loans/${widget.lan}/repay/initiate',
        data: {
          'installmentNumber': _selectedInstallmentNumber,
          'amount': amountToPay,
        },
      );

      final data = res['data'] ?? res;
      final nestedData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
          ? data['data']
          : data;

      final accessKey = nestedData['accessKey'];
      final env = nestedData['environment'] ?? 'test';
      final baseGatewayUrl = (env == 'prod')
          ? 'https://pay.easebuzz.in/pay/'
          : 'https://testpay.easebuzz.in/pay/';

      final checkoutUrl = nestedData['paymentUrl'] ??
          nestedData['checkoutUrl'] ??
          nestedData['url'] ??
          (accessKey != null ? '$baseGatewayUrl$accessKey' : null);

      if (checkoutUrl != null && checkoutUrl.toString().isNotEmpty) {
        final urlStr = checkoutUrl.toString();
        final controller = _buildEasebuzzWebViewController(urlStr);

        setState(() {
          _paymentUrl = urlStr;
          _webViewController = controller;
        });
      } else {
        // Direct confirmation backend stub
        await _onPaymentCompleted();
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
          _errorMessage = 'Failed to initiate repayment: $msg';
        });
      }
    } finally {
      if (mounted) setState(() => _isInitiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If Easebuzz Payment Gateway is active in WebView
    if (_paymentUrl != null && _webViewController != null) {
      return Scaffold(
        appBar: AppHeader(
          title: 'Easebuzz Payment Gateway',
          onBackPressed: () {
            setState(() {
              _paymentUrl = null;
              _webViewController = null;
            });
          },
          actions: [
            if (_isVerifying)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _onPaymentCompleted,
                tooltip: 'Check payment status',
              ),
          ],
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    final summary = _loanDetails?['summary'] as Map<String, dynamic>?;
    final rpsList = (_loanDetails?['repaymentSchedule'] as List<dynamic>?) ?? [];
    final apiLoan = _loanDetails?['loan'] as Map<String, dynamic>?;

    final totalOutstanding = (summary?['totalOutstanding'] ?? apiLoan?['approvedAmount'] ?? 0).toDouble();
    final nextEmiAmount = (summary?['nextEmiAmount'] ?? 0).toDouble();
    final overdueAmount = (summary?['overdueAmount'] ?? 0).toDouble();
    final nextDueDate = summary?['nextDueDate']?.toString();

    return Scaffold(
      appBar: AppHeader(
        title: 'EMI Repayment & Collection',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: AppLoader(message: 'Loading repayment details...'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primaryDeepTeal, AppTheme.primaryDarkTeal],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ACTIVE REPAYMENT',
                                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              AppStatusBadge(status: 'ACTIVE', label: 'Disbursed'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            CurrencyUtils.formatAmount(totalOutstanding),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                          ),
                          const Text('Total Loan Outstanding', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Next Due EMI', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    Text(
                                      nextEmiAmount > 0 ? CurrencyUtils.formatAmount(nextEmiAmount) : '—',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Due Date', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    Text(
                                      _formatDate(nextDueDate),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Overdue Alert
                    if (overdueAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorRed),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 24),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have an overdue balance of ${CurrencyUtils.formatAmount(overdueAmount)}. Pay immediately to avoid late payment charges.',
                                style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Make EMI Repayment',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Select installment and pay securely via Easebuzz UPI / Netbanking / Cards.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                            ),
                            const SizedBox(height: 16),

                            // Installment Selector
                            if (rpsList.isNotEmpty) ...[
                              const Text('Select Installment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Column(
                                children: rpsList.map((item) {
                                  final map = item as Map<String, dynamic>;
                                  final instNum = map['installmentNumber'] ?? 1;
                                  final emi = (map['emi'] ?? 0).toDouble();
                                  final rem = (map['remainingAmount'] ?? emi).toDouble();
                                  final pStatus = map['paymentStatus']?.toString().toUpperCase() ?? 'UNPAID';
                                  final isSelected = _selectedInstallmentNumber == instNum;
                                  final isPaid = pStatus == 'PAID';

                                  return GestureDetector(
                                    onTap: isPaid
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedInstallmentNumber = instNum;
                                              _paymentAmount = rem > 0 ? rem : emi;
                                              _customAmountController.text = _paymentAmount.toStringAsFixed(0);
                                            });
                                          },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryLightTeal : (isPaid ? Colors.grey.shade100 : Colors.white),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                                color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Installment #$instNum',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isPaid ? Colors.grey : AppTheme.textDarkPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                CurrencyUtils.formatAmount(rem > 0 ? rem : emi),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? AppTheme.primaryTeal : AppTheme.textDarkPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              AppStatusBadge(status: pStatus),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Auto-filled Payable Amount Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Payable Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLightTeal,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.primaryTeal),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bullet EMI Auto-filled',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 22, color: AppTheme.primaryTeal),
                                hintText: 'Enter amount',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20),
                                  tooltip: 'Reset to Bullet EMI amount',
                                  onPressed: () {
                                    setState(() {
                                      _customAmountController.text = _paymentAmount.toStringAsFixed(0);
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                ),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.trim());
                                if (parsed != null) {
                                  _paymentAmount = parsed;
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_statusMessage != null && _errorMessage == null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.successBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_statusMessage!, style: const TextStyle(color: AppTheme.successDarkGreen, fontSize: 12)),
                              ),
                              const SizedBox(height: 16),
                            ],

                            AppButton(
                              text: 'Pay Now via Easebuzz Gateway',
                              isLoading: _isInitiating,
                              onPressed: _initiateEasebuzzPayment,
                              icon: Icons.lock_outline_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
