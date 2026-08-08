import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ProcessingFeeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? eligibilityData;

  const ProcessingFeeScreen({super.key, this.eligibilityData});

  @override
  ConsumerState<ProcessingFeeScreen> createState() => _ProcessingFeeScreenState();
}

class _ProcessingFeeScreenState extends ConsumerState<ProcessingFeeScreen> {
  bool _isInitiating = false;
  bool _isVerifying = false;
  String? _paymentUrl;
  String? _txnid;
  String? _paymentId;
  String? _errorMessage;
  WebViewController? _webViewController;
  Timer? _statusTimer;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiatePayment();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  String _getLenderName(String? lenderId) {
    if (lenderId == 'cms62saaa0001tsmcksp92trc') {
      return 'Fintree Finance Pvt Lt';
    }
    if (lenderId != null && lenderId.isNotEmpty) {
      return 'Partner Lender ($lenderId)';
    }
    return 'Partner Lender';
  }

  void _initiatePayment() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    if (customer.assessmentFeePaid) {
      if (mounted) {
        context.go('/dashboard');
      }
      return;
    }

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final eligibility = widget.eligibilityData;
      final assessmentFee = eligibility?['data']?['assessmentFee'] ?? eligibility?['assessmentFee'] ?? customer.assessmentFee;
      final feeAmount = (assessmentFee?['baseAmount'] ?? 499) as num;

      final String? lenderId = eligibility?['data']?['lenderId'] ?? eligibility?['lenderId'] ?? customer.allocatedLenderCode;
      final String? allocatedLenderName = customer.allocatedLenderName;
      final String lenderName = (allocatedLenderName != null && allocatedLenderName.isNotEmpty) 
          ? allocatedLenderName 
          : _getLenderName(lenderId);

      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/external-api/initiate-payment',
        data: {
          'customerId': customer.id,
          'amount': feeAmount,
          'purpose': 'ASSESSMENT_FEE',
          'consentTemplateId': 'LENDER_DATA_SHARING_V1',
          'consentVersion': '1.0',
          'consentText': 'I consent to share my application data with $lenderName for eligibility assessment and final decision.',
        },
      );

      final data = res['data'] ?? res;
      final nestedData = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) 
          ? data['data'] 
          : data;
      final accessKey = nestedData['accessKey'];
      final environment = nestedData['environment'] ?? 'test';
      final basePaymentUrl = (environment == 'prod') 
          ? 'https://pay.easebuzz.in/pay/' 
          : 'https://testpay.easebuzz.in/pay/';

      _paymentUrl = nestedData['paymentUrl'] ?? nestedData['url'] ?? (accessKey != null ? '$basePaymentUrl$accessKey' : null);
      _paymentId = nestedData['paymentId']?.toString();
      _txnid = nestedData['txnid'] ?? nestedData['transactionId'];

      if (_paymentUrl != null) {
        _statusTimer?.cancel();
        _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!_isVerifying && mounted) {
            _verifyPaymentStatus();
          }
        });

        setState(() {
          _webViewController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageFinished: (String url) {
                  final lowerUrl = url.toLowerCase();
                  if (lowerUrl.contains('success') || 
                      lowerUrl.contains('failure') || 
                      lowerUrl.contains('status') || 
                      lowerUrl.contains('result') || 
                      lowerUrl.contains('webhook')) {
                    _verifyPaymentStatus();
                  }
                },
                onNavigationRequest: (NavigationRequest request) {
                  final url = request.url.toLowerCase();
                  if (url.contains('success') || 
                      url.contains('failure') || 
                      url.contains('status') || 
                      url.contains('result') || 
                      url.contains('processing-fee') ||
                      url.contains('details') ||
                      url.contains('webhook')) {
                    _verifyPaymentStatus();
                    return NavigationDecision.prevent;
                  }
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(_paymentUrl!));
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

  void _verifyPaymentStatus() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      bool paid = false;

      if (_paymentId != null && _txnid != null) {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.post(
          '/external-api/payment-status',
          data: {
            'paymentId': _paymentId ?? '',
            'transactionId': _txnid ?? '',
            'purpose': 'ASSESSMENT_FEE',
          },
        );

        final data = res['data'] ?? res;
        if (data['paymentCompleted'] == true || 
            data['status']?.toString().toUpperCase() == 'SUCCESS' || 
            res['status']?.toString().toUpperCase() == 'SUCCESS' || 
            res['paid'] == true) {
          paid = true;
        }
      }

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      final updatedCustomer = ref.read(journeyControllerProvider).customer;
      if (updatedCustomer?.assessmentFeePaid == true) {
        paid = true;
      }

      if (paid && mounted) {
        _statusTimer?.cancel();
        setState(() {
          _isSuccess = true;
          _isVerifying = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Payment status pending or not confirmed. Please retry after completing payment.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;
    final eligibility = widget.eligibilityData;
    final assessmentFee = eligibility?['data']?['assessmentFee'] ?? eligibility?['assessmentFee'] ?? customer?.assessmentFee;
    
    final num feeAmount = (assessmentFee?['baseAmount'] ?? 499) as num;
    final num gstAmount = (assessmentFee?['gstAmount'] ?? (feeAmount * 0.18)) as num;
    final num totalAmount = (assessmentFee?['totalAmount'] ?? (feeAmount + gstAmount)) as num;
    
    final String? lenderId = eligibility?['data']?['lenderId'] ?? eligibility?['lenderId'] ?? customer?.allocatedLenderCode;
    final String? allocatedLenderName = customer?.allocatedLenderName;
    final String lenderName = (allocatedLenderName != null && allocatedLenderName.isNotEmpty) 
        ? allocatedLenderName 
        : _getLenderName(lenderId);

    if (_isSuccess) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppTheme.successGreen,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your assessment fee has been verified successfully. You can now proceed with the remaining onboarding steps.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDarkSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _row('Allocated Lender', lenderName),
                        _row('Amount Paid', CurrencyUtils.formatAmount(totalAmount, showDecimals: true)),
                        if (_txnid != null) _row('Transaction ID', _txnid!),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                AppButton(
                  text: 'Continue Onboarding',
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Fee Payment'),
      ),
      body: SafeArea(
        child: _paymentUrl != null && _webViewController != null
            ? Column(
                children: [
                  Expanded(
                    child: WebViewWidget(controller: _webViewController!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppButton(
                      text: 'Confirm Payment Status',
                      onPressed: _verifyPaymentStatus,
                      icon: Icons.refresh_rounded,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Assessment & Processing Fee',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDarkPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pay the non-refundable processing fee to initiate credit check and underwriting.',
                      style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _row('Allocated Lender', lenderName),
                            _row('Processing Fee', CurrencyUtils.formatAmount(feeAmount)),
                            _row('GST', CurrencyUtils.formatAmount(gstAmount, showDecimals: true)),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  CurrencyUtils.formatAmount(totalAmount, showDecimals: true),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryTeal),
                                ),
                              ],
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
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_isVerifying)
                      const AppLoader(message: 'Verifying payment with payment gateway...')
                    else
                      AppButton(
                        text: 'Pay ${CurrencyUtils.formatAmount(totalAmount, showDecimals: true)}',
                        isLoading: _isInitiating,
                        onPressed: _initiatePayment,
                        icon: Icons.payment_rounded,
                      ),
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
