import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class PanVerificationScreen extends ConsumerStatefulWidget {
  const PanVerificationScreen({super.key});

  @override
  ConsumerState<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends ConsumerState<PanVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _verifiedResult;

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  void _verifyPan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final apiClient = ref.read(apiClientProvider);

      if (customerId != null) {
        final res = await apiClient.post(
          '/external-api/verify-pan',
          data: {
            'customerId': customerId,
            'panNumber': _panController.text.trim().toUpperCase(),
          },
        );

        setState(() {
          _verifiedResult = res['data'] ?? res;
        });

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continue() {
    context.push('/onboarding/basic-details');
  }

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;
    final isAlreadyVerified = customer?.panVerified == true || _verifiedResult != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAN Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppStepper(
                  currentStep: 1,
                  totalSteps: 5,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'Submit'],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your PAN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your 10-character Permanent Account Number (PAN) for identity verification.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'PAN Number',
                  hint: 'ABCDE1234F',
                  controller: _panController,
                  validator: Validators.validatePan,
                  textCapitalization: TextCapitalization.characters,
                  readOnly: isAlreadyVerified,
                  prefix: const Icon(Icons.badge_outlined, size: 20),
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
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isAlreadyVerified) ...[
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
                              Text(
                                'PAN Verification Details',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              AppStatusBadge(status: 'VERIFIED', label: 'Verified'),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Masked PAN', Formatters.maskPan(customer?.panNumber ?? _panController.text)),
                          _buildDetailRow('Verified Name', customer?.fullName ?? _verifiedResult?['fullName'] ?? 'N/A'),
                          _buildDetailRow('Date of Birth', customer?.dateOfBirth ?? _verifiedResult?['dateOfBirth'] ?? 'N/A'),
                          _buildDetailRow('Gender', customer?.gender ?? _verifiedResult?['gender'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (!isAlreadyVerified)
                  AppButton(
                    text: 'Verify PAN',
                    isLoading: _isLoading,
                    onPressed: _verifyPan,
                    icon: Icons.check_circle_outline,
                  )
                else
                  AppButton(
                    text: 'Continue',
                    onPressed: _continue,
                    icon: Icons.arrow_forward_rounded,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkPrimary)),
        ],
      ),
    );
  }
}
