import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _consentGiven = true;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept customer consent to proceed.')),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(_mobileController.text.trim(), _consentGiven);

    if (success && mounted) {
      context.push('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 54,
                  color: AppTheme.primaryTeal,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Personal Loan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your registered 10-digit mobile number to receive a verification OTP.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Mobile Number',
                  hint: 'Enter 10-digit mobile number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validateMobile,
                  prefix: const Icon(Icons.phone_android_rounded, size: 20),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _consentGiven,
                      activeColor: AppTheme.primaryTeal,
                      onChanged: (val) {
                        setState(() {
                          _consentGiven = val == true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          'I hereby consent to receiving OTP, loan communications, and accept terms & conditions for Personal Loan processing.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (state.errorMessage != null) ...[
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
                            state.errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  text: 'Get Verification OTP',
                  isLoading: state.isLoading,
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
