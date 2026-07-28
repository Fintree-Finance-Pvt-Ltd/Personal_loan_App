import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ProcessingFeeScreen extends ConsumerStatefulWidget {
  const ProcessingFeeScreen({super.key});

  @override
  ConsumerState<ProcessingFeeScreen> createState() => _ProcessingFeeScreenState();
}

class _ProcessingFeeScreenState extends ConsumerState<ProcessingFeeScreen> {
  bool _isInitiating = false;
  bool _isVerifying = false;
  String? _paymentUrl;
  String? _txnid;
  String? _errorMessage;

  void _initiatePayment() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    setState(() {
      _isInitiating = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/external-api/initiate-payment',
        data: {
          'customerId': customer.id,
          'amount': 499,
          'purpose': 'ASSESSMENT_FEE',
        },
      );

      final data = res['data'] ?? res;
      _paymentUrl = data['paymentUrl'] ?? data['url'];
      _txnid = data['txnid'];

      if (_paymentUrl != null) {
        final uri = Uri.parse(_paymentUrl!);
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

  void _verifyPaymentStatus() async {
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/external-api/payment-status',
        data: {
          'customerId': customer.id,
          'txnid': _txnid ?? '',
        },
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      final paid = res['status'] == 'SUCCESS' || res['paid'] == true || ref.read(journeyControllerProvider).customer?.assessmentFeePaid == true;

      if (paid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verified successfully!')),
        );
        context.go('/application/status');
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
    const feeAmount = 499;
    const gstAmount = 89.82;
    const totalAmount = 588.82;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Fee Payment'),
      ),
      body: SafeArea(
        child: Padding(
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
                      _row('Processing Fee', CurrencyUtils.formatAmount(feeAmount)),
                      _row('18% GST', CurrencyUtils.formatAmount(gstAmount, showDecimals: true)),
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
              else ...[
                AppButton(
                  text: 'Pay ${CurrencyUtils.formatAmount(totalAmount, showDecimals: true)}',
                  isLoading: _isInitiating,
                  onPressed: _initiatePayment,
                  icon: Icons.payment_rounded,
                ),
                if (_paymentUrl != null) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Confirm Payment Status',
                    isOutlined: true,
                    onPressed: _verifyPaymentStatus,
                    icon: Icons.refresh_rounded,
                  ),
                ],
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
