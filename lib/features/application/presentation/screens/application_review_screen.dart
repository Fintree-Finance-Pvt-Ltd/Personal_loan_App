import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/animated_page.dart';
import '../../../../core/widgets/journey_progress.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class ApplicationReviewScreen extends ConsumerStatefulWidget {
  const ApplicationReviewScreen({super.key});

  @override
  ConsumerState<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends ConsumerState<ApplicationReviewScreen> {
  bool _consent = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  void _submitApplication() async {
    if (!_consent) return;

    final customerId = ref.read(journeyControllerProvider).customer?.id;
    if (customerId == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final customerApi = ref.read(customerApiProvider);
      final customer = ref.read(journeyControllerProvider).customer;
      
      // Step 1: Accept Decision Consents with dynamic or server consent texts
      await customerApi.acceptLenderDecisionConsents(
        customConsentTexts: customer?.consentTexts,
      );

      // Step 2: Submit Application
      await customerApi.submitCustomerApplication(customerId);

      await ref.read(journeyControllerProvider.notifier).syncCustomerState();

      if (mounted) {
        context.go('/application/status');
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;
    final lenderName = customer?.allocatedLenderName ?? 'the allocated lending partner';

    final bureauText = customer?.consentTexts?['BUREAU_ENQUIRY']?['text'] as String? ??
        'I authorize a bureau enquiry for this loan application.';
    final assessmentText = customer?.consentTexts?['LENDER_CREDIT_ASSESSMENT']?['text'] as String? ??
        'I authorize the allocated lender to assess my eligibility and credit profile.';
    final decisionText = customer?.consentTexts?['LENDER_DECISION_REQUEST']?['text'] as String? ??
        'I authorize submission of my completed application to the allocated lender for a lending decision.';

    return Scaffold(
      appBar: const AppHeader(
        title: 'Review Application',
        fallbackRoute: '/onboarding/address',
      ),
      body: SafeArea(
        child: AnimatedPage(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Continuous Journey Progress Header
                const AnimatedSection(
                  delay: Duration(milliseconds: 50),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: JourneyProgress(
                      currentStep: LoanJourneyStep.application,
                      compact: true,
                    ),
                  ),
                ),

                const AnimatedSection(
                  delay: Duration(milliseconds: 90),
                  child: AppStepper(
                    currentStep: 7,
                    totalSteps: 7,
                    stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'DigiLocker KYC', 'Address Confirmation', 'Review & Submit'],
                  ),
                ),

                const SizedBox(height: 20),

                const AnimatedSection(
                  delay: Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Application Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please verify all information before submitting to credit review.',
                        style: TextStyle(fontSize: 13.5, color: AppTheme.textDarkSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                AnimatedSection(
                  delay: const Duration(milliseconds: 150),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
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
                ),

                const SizedBox(height: 14),

                AnimatedSection(
                  delay: const Duration(milliseconds: 180),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
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
                ),

                const SizedBox(height: 18),

                AnimatedSection(
                  delay: const Duration(milliseconds: 210),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gavel_rounded, color: AppTheme.primaryTeal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Required Authorizations ($lenderName)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDarkPrimary),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _consentBullet('Credit Bureau Enquiry', bureauText),
                          const SizedBox(height: 12),
                          _consentBullet('Credit Profile Assessment', assessmentText),
                          const SizedBox(height: 12),
                          _consentBullet('Final Decision Submission', decisionText),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                AnimatedSection(
                  delay: const Duration(milliseconds: 240),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consent,
                        activeColor: AppTheme.primaryTeal,
                        onChanged: (v) => setState(() => _consent = v == true),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _consent = !_consent),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'I have read and agree to all the above mandatory authorizations for loan submission.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary, height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  AnimatedSection(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                AnimatedSection(
                  delay: const Duration(milliseconds: 270),
                  child: AppButton(
                    text: 'Submit Application',
                    isLoading: _isSubmitting,
                    onPressed: (_consent && !_isSubmitting) ? _submitApplication : null,
                    icon: Icons.send_rounded,
                  ),
                ),
              ],
            ),
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

  Widget _consentBullet(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryTeal, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
