import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_stepper.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';

class BasicDetailsScreen extends ConsumerStatefulWidget {
  const BasicDetailsScreen({super.key});

  @override
  ConsumerState<BasicDetailsScreen> createState() => _BasicDetailsScreenState();
}

class _BasicDetailsScreenState extends ConsumerState<BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fatherNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(journeyControllerProvider).customer;
    if (customer != null) {
      if (customer.fatherName != null) _fatherNameController.text = customer.fatherName!;
      if (customer.email != null) _emailController.text = customer.email!;
      if (customer.residentialPincode != null) _pincodeController.text = customer.residentialPincode!;
    }
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerId = ref.read(journeyControllerProvider).customer?.id;
      final apiClient = ref.read(apiClientProvider);

      if (customerId != null) {
        // Update basic details
        await apiClient.patch(
          '/customer/$customerId/basic-details',
          data: {
            'fatherName': _fatherNameController.text.trim(),
            'email': _emailController.text.trim(),
            'residentialPincode': _pincodeController.text.trim(),
          },
        );

        // Update pincode & city info
        await apiClient.patch(
          '/customer/$customerId/pincode',
          data: {
            'pincode': _pincodeController.text.trim(),
          },
        );

        await ref.read(journeyControllerProvider.notifier).syncCustomerState();
        if (mounted) {
          context.push('/onboarding/profile');
        }
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

  @override
  Widget build(BuildContext context) {
    final customer = ref.watch(journeyControllerProvider).customer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
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
                  currentStep: 2,
                  totalSteps: 5,
                  stepTitles: ['PAN Verification', 'Personal Details', 'Profile & Income', 'Photo & Liveness', 'Submit'],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Basic Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please provide your personal details to complete your profile.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textDarkSecondary),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name (As per PAN)',
                  controller: TextEditingController(text: customer?.fullName ?? ''),
                  readOnly: true,
                  prefix: const Icon(Icons.person_outline, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Father's Full Name",
                  hint: "Enter father's full name",
                  controller: _fatherNameController,
                  validator: (v) => Validators.validateRequired(v, "Father's name"),
                  textCapitalization: TextCapitalization.words,
                  prefix: const Icon(Icons.people_outline, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email Address',
                  hint: 'example@domain.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefix: const Icon(Icons.email_outlined, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Residential PIN Code',
                  hint: '6-digit PIN code',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validatePincode,
                  prefix: const Icon(Icons.pin_drop_outlined, size: 20),
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
                const SizedBox(height: 32),
                AppButton(
                  text: 'Save & Continue',
                  isLoading: _isLoading,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
