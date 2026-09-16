import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../dashboard/presentation/journey_controller.dart';
import '../auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;

  int _secondsRemaining = AppConstants.otpResendCooldownSeconds;
  int _resendAttempts = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });

    _listenForSms();
  }

  Future<void> _listenForSms() async {
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi();
      if (res.hasData && res.data!.code != null) {
        if (mounted) {
          final code = res.data!.code!.replaceAll(RegExp(r'\D'), '');
          if (code.length == 6) {
            setState(() {
              _otpController.text = code;
            });
            TextInput.finishAutofillContext();
            _verify();
          }
        }
      }
    } catch (_) {
      // Ignore errors from smart_auth
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _secondsRemaining = AppConstants.otpResendCooldownSeconds;
      });
    } else {
      _secondsRemaining = AppConstants.otpResendCooldownSeconds;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    SmartAuth.instance.removeUserConsentApiListener();
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _goBack() {
    FocusScope.of(context).unfocus();

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _resendOtp() async {
    final authState = ref.read(authControllerProvider);

    if (authState.isLoading || _secondsRemaining > 0) {
      return;
    }

    if (_resendAttempts >= AppConstants.maxOtpAttempts) {
      _showMessage(
        'Maximum OTP resend limit reached. Please try again later.',
        isError: true,
      );
      return;
    }

    final mobile = authState.mobileNumber;

    if (mobile == null || mobile.trim().isEmpty) {
      _showMessage(
        'Mobile number is unavailable. Please return to the login screen.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(mobile, true);

    if (!mounted) return;

    if (success) {
      setState(() {
        _resendAttempts++;
        _otpController.clear();
      });

      _startTimer();

      _showMessage(
        'A new verification OTP has been sent successfully.',
      );

      Future.delayed(
        const Duration(milliseconds: 300),
        () {
          if (mounted) {
            _otpFocusNode.requestFocus();
          }
        },
      );
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final customer = await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          _otpController.text.trim(),
        );

    if (customer == null || !mounted) return;

    // Send automated successful login push notification
    PushNotificationService().sendLoginSuccessNotification(
      userName: customer.fullName,
    );

    await ref
        .read(journeyControllerProvider.notifier)
        .syncCustomerState();

    final targetRoute = ref.read(journeyControllerProvider).targetRoute;
    context.go(targetRoute);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? AppTheme.errorRed : AppTheme.primaryTeal,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final maskedMobile = Formatters.maskMobile(state.mobileNumber);
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppHeader(
        title: ref.watch(appLocalizationsProvider).tr('verify_otp_title'),
        onBackPressed: _goBack,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: mediaQuery.viewInsets.bottom > 0
                    ? mediaQuery.viewInsets.bottom + 16
                    : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // ==========================================
                          // PROMINENT LARGE LOGO HEADER
                          // ==========================================
                          _buildLargeLogoHeader(maskedMobile),

                          const SizedBox(height: 32),

                          // ==========================================
                          // FORM CARD
                          // ==========================================
                          _buildFormCard(state, maskedMobile),

                          const Spacer(),

                          const SizedBox(height: 24),

                          // ==========================================
                          // TRUST & SECURITY FOOTER
                          // ==========================================
                          const _SecurityFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLargeLogoHeader(String maskedMobile) {
    return Column(
      children: [
        // Prominent Logo Container
        Container(
          height: 110,
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDeepTeal.withValues(alpha: 0.08),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'lib/assets/images/Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    color: AppTheme.primaryTeal,
                    size: 48,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'BRAND LOGO',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Flat Stylized Headline
        // ShaderMask(
        //   blendMode: BlendMode.srcIn,
        //   shaderCallback: (bounds) => const LinearGradient(
        //     colors: [
        //       AppTheme.primaryTeal,
        //       AppTheme.accentCyan,
        //     ],
        //     begin: Alignment.centerLeft,
        //     end: Alignment.centerRight,
        //   ).createShader(bounds),
        //   child: const Text(
        //     '',
        //     textAlign: TextAlign.center,
        //     style: TextStyle(
        //       fontSize: 32,
        //       fontWeight: FontWeight.w900,
        //       fontStyle: FontStyle.italic,
        //       letterSpacing: -0.5,
        //     ),
        //   ),
        // ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Enter the 6-digit OTP sent to $maskedMobile',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _goBack,
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(dynamic state, String maskedMobile) {
    const maximumResends = AppConstants.maxOtpAttempts;
    final remainingResends = (maximumResends - _resendAttempts).clamp(
      0,
      maximumResends,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'We sent a 6-digit verification code to your phone',
                style: TextStyle(
                  color: AppTheme.textDarkSecondary.withValues(alpha: 0.9),
                  fontSize: 12.5,
                ),
              ),

              const SizedBox(height: 24),

              // OTP Code Field
              _OtpCodeField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                enabled: !state.isLoading,
                validator: Validators.validateOtp,
                onChanged: (_) {
                  setState(() {});
                  if (_otpController.text.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
                onSubmitted: (_) {
                  if (!state.isLoading) {
                    _verify();
                  }
                },
              ),

              const SizedBox(height: 22),

              // Resend Section
              _buildResendSection(
                isLoading: state.isLoading,
                remainingResends: remainingResends,
              ),

              // Error State Banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: state.errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(state.errorMessage),
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.errorRed.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Verify OTP & Continue',
                  isLoading: state.isLoading,
                  onPressed: _verify,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection({
    required bool isLoading,
    required int remainingResends,
  }) {
    const totalSeconds = AppConstants.otpResendCooldownSeconds;
    final progress = totalSeconds <= 0
        ? 0.0
        : (_secondsRemaining / totalSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderMuted,
        ),
      ),
      child: Row(
        children: [
          if (_secondsRemaining > 0)
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor:
                          AppTheme.primaryTeal.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                  Text(
                    '$_secondsRemaining',
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLightTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryTeal,
                size: 22,
              ),
            ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _secondsRemaining > 0
                      ? 'Didn\'t receive the code?'
                      : 'You can request a new code',
                  style: const TextStyle(
                    color: AppTheme.textDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _secondsRemaining > 0
                      ? 'Resend available in $_secondsRemaining seconds'
                      : '$remainingResends resend attempt(s) remaining',
                  style: const TextStyle(
                    color: AppTheme.textDarkSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (_secondsRemaining == 0)
            TextButton(
              onPressed:
                  isLoading || remainingResends <= 0 ? null : _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Resend',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OtpCodeField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? Function(String?) validator;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _OtpCodeField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.validator,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<_OtpCodeField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator(widget.controller.text),
      initialValue: widget.controller.text,
      builder: (fieldState) {
        // Keep FormField value synced with controller on programmatic text changes / autofill
        if (fieldState.value != widget.controller.text) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (fieldState.mounted) {
              fieldState.didChange(widget.controller.text);
            }
          });
        }

        final hasError = fieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Hidden TextField capturing keyboard inputs
                Opacity(
                  opacity: 0.01,
                  child: SizedBox(
                    height: 52,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (val) {
                        fieldState.didChange(val);
                        widget.onChanged(val);
                      },
                      onSubmitted: widget.onSubmitted,
                    ),
                  ),
                ),

                // Custom 6-Box Visual Grid
                GestureDetector(
                  onTap: () {
                    if (widget.enabled) {
                      widget.focusNode.requestFocus();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      final code = widget.controller.text;
                      final isFilled = index < code.length;
                      final isFocused = widget.focusNode.hasFocus &&
                          (index == code.length ||
                              (index == 5 && code.length == 6));

                      final char = isFilled ? code[index] : '';

                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.symmetric(
                            horizontal: index == 0 || index == 5 ? 2 : 3,
                          ),
                          height: 52,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? AppTheme.primaryLightTeal.withValues(alpha: 0.5)
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasError
                                  ? AppTheme.errorRed
                                  : isFocused
                                      ? AppTheme.primaryTeal
                                      : isFilled
                                          ? AppTheme.primaryTeal.withValues(alpha: 0.4)
                                          : AppTheme.borderLight,
                              width: isFocused ? 2 : 1.2,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryTeal
                                          .withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: const TextStyle(
                                color: AppTheme.textDarkPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryLightTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 16,
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '100% Safe & 256-bit Encrypted',
              style: TextStyle(
                color: AppTheme.textDarkSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}