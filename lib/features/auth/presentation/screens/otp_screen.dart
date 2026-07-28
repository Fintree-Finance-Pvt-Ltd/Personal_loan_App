import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../dashboard/presentation/journey_controller.dart';
import '../auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  int _secondsRemaining = AppConstants.otpResendCooldownSeconds;
  Timer? _timer;
  int _resendAttempts = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = AppConstants.otpResendCooldownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _resendOtp() async {
    if (_resendAttempts >= AppConstants.maxOtpAttempts) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum OTP resend limit reached. Please try later.')),
        );
      }
      return;
    }
    final mobile = ref.read(authControllerProvider).mobileNumber;
    if (mobile != null) {
      _resendAttempts++;
      final success = await ref.read(authControllerProvider.notifier).sendOtp(mobile, true);
      if (success && mounted) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification OTP resent successfully.')),
        );
      }
    }
  }

  void _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(_otpController.text.trim());

    if (customer != null && mounted) {
      await ref.read(journeyControllerProvider.notifier).syncCustomerState();
      if (!mounted) return;
      final target = ref.read(journeyControllerProvider).targetRoute;
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final maskedMobile = Formatters.maskMobile(state.mobileNumber);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Mobile OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Code sent to $maskedMobile',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the 6-digit OTP sent via SMS to confirm your identity.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Verification Code (OTP)',
                  hint: '6-digit code',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateOtp,
                  prefix: const Icon(Icons.lock_clock_outlined, size: 20),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_secondsRemaining > 0)
                      Text(
                        'Resend OTP in ${_secondsRemaining}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDarkSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _resendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
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
                  text: 'Verify & Continue',
                  isLoading: state.isLoading,
                  onPressed: _verify,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
