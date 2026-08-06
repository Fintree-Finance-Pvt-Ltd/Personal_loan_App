import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ApplicationReviewScreen extends ConsumerStatefulWidget {
  const ApplicationReviewScreen({super.key});

  @override
  ConsumerState<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends ConsumerState<ApplicationReviewScreen> {
  bool _consent = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  void _submitApplication() async {
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms & declaration to submit.')),
      );
      return;
    }

    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/customer/$customerId/submit-application',
        data: {'customerId': customerId},
      );

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.go('/application/status');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Application'),
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
                stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'DigiLocker KYC', 'Address Confirmation', 'Review & Submit'],
              ),
              const SizedBox(height: 24),
              const Text(
                'Review Application Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please verify all information before submitting to credit review.',
                style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Personal Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          AppStatusBadge(status: 'VERIFIED'),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Full Name', customer?.fullName ?? 'N/A'),
                      _row('Father Name', customer?.fatherName ?? 'N/A'),
                      _row('PAN Number', Formatters.maskPan(customer?.panNumber)),
                      _row('Email', customer?.email ?? 'N/A'),
                      _row('Residential PIN', customer?.residentialPincode ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Employment & Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 20),
                      _row('Employment Type', customer?.employmentType ?? 'N/A'),
                      if (customer?.employmentType == 'SALARIED') ...[
                        _row('Company', customer?.companyName ?? 'N/A'),
                        _row('Designation', customer?.designation ?? 'N/A'),
                      ] else ...[
                        _row('Business Name', customer?.businessName ?? 'N/A'),
                      ],
                      _row('Monthly Net Income', CurrencyUtils.formatAmount(customer?.monthlyIncome)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consent,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (v) => setState(() => _consent = v == true),
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        'I declare that all provided information is accurate and give consent to evaluate my loan application.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 32),
              AppButton(
                text: 'Submit Loan Application',
                isLoading: _isSubmitting,
                onPressed: _submitApplication,
                icon: Icons.send_rounded,
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
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
