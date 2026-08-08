import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../dashboard/presentation/journey_controller.dart';
import '../auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;

  int _secondsRemaining = AppConstants.otpResendCooldownSeconds;
  int _resendAttempts = 0;

  late final AnimationController _introController;
  late final AnimationController _floatingController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.05,
        1,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0,
          0.70,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.20,
          1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _introController.forward();
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _secondsRemaining =
            AppConstants.otpResendCooldownSeconds;
      });
    } else {
      _secondsRemaining =
          AppConstants.otpResendCooldownSeconds;
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
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _introController.dispose();
    _floatingController.dispose();
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

    await ref
        .read(journeyControllerProvider.notifier)
        .syncCustomerState();

    if (!mounted) return;

    final targetRoute =
        ref.read(journeyControllerProvider).targetRoute;

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
          backgroundColor: isError
              ? AppTheme.errorRed
              : AppTheme.primaryTeal,
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
    final maskedMobile =
        Formatters.maskMobile(state.mobileNumber);

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3F8F8),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0xFFF3F8F8),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: _buildBackground(),
          ),

          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: mediaQuery.viewInsets.bottom > 0
                        ? mediaQuery.viewInsets.bottom + 16
                        : 26,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: _buildHeader(
                            maskedMobile,
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -26),
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildOtpCard(
                                state.isLoading,
                                state.errorMessage,
                                maskedMobile,
                              ),
                            ),
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -5),
                          child: const _SecurityFooter(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF043B43),
                Color(0xFF007E79),
                Color(0xFF15AFA2),
              ],
            ),
          ),
        ),

        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final value = _floatingController.value;

            return Stack(
              children: [
                Positioned(
                  top: 22 + (value * 14),
                  right: -42,
                  child: const _FloatingCircle(
                    size: 150,
                    opacity: 0.08,
                  ),
                ),
                Positioned(
                  top: 165 - (value * 11),
                  left: -55,
                  child: const _FloatingCircle(
                    size: 125,
                    opacity: 0.07,
                  ),
                ),
                Positioned(
                  top: 90 + (value * 8),
                  right: 72,
                  child: const _FloatingCircle(
                    size: 40,
                    opacity: 0.11,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(String maskedMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        36,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _goBack,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  height: 48,
                  constraints: const BoxConstraints(
                    minWidth: 54,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/images/Logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.account_balance_rounded,
                        color: AppTheme.primaryTeal,
                        size: 28,
                      );
                    },
                  ),
                ),
              ],
            ),

            const Spacer(),

            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      color: AppTheme.primaryTeal,
                      size: 31,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Verify your mobile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'We sent a secure 6-digit OTP to $maskedMobile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.84),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpCard(
    bool isLoading,
    String? errorMessage,
    String maskedMobile,
  ) {
    final maximumResends = AppConstants.maxOtpAttempts;

    final remainingResends =
        (maximumResends - _resendAttempts).clamp(
      0,
      maximumResends,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(
        22,
        26,
        22,
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE0EBEB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063B43).withOpacity(0.11),
            blurRadius: 35,
            spreadRadius: 1,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter verification code',
                style: TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Enter the code sent by SMS to $maskedMobile.',
                style: const TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 25),

              _OtpCodeField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                enabled: !isLoading,
                validator: Validators.validateOtp,
                onChanged: (_) {
                  setState(() {});

                  if (_otpController.text.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
                onSubmitted: (_) {
                  if (!isLoading) {
                    _verify();
                  }
                },
              ),

              const SizedBox(height: 22),

              _buildResendSection(
                isLoading: isLoading,
                remainingResends: remainingResends,
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(errorMessage),
                        padding: const EdgeInsets.only(top: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  AppTheme.errorRed.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Verify & Continue',
                  isLoading: isLoading,
                  onPressed: _verify,
                  icon: Icons.verified_outlined,
                ),
              ),

              const SizedBox(height: 16),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF718789),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'OTP verification is encrypted and secure',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718789),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
    final totalSeconds =
        AppConstants.otpResendCooldownSeconds;

    final progress = totalSeconds <= 0
        ? 0.0
        : (_secondsRemaining / totalSeconds).clamp(
            0.0,
            1.0,
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1EBEB),
        ),
      ),
      child: Row(
        children: [
          if (_secondsRemaining > 0)
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor:
                          AppTheme.primaryTeal.withOpacity(0.12),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
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
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryTeal,
                size: 23,
              ),
            ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _secondsRemaining > 0
                      ? 'Didn\'t receive the OTP?'
                      : 'You can request a new OTP',
                  style: const TextStyle(
                    color: AppTheme.textDarkPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
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
              onPressed: isLoading ||
                      remainingResends <= 0
                  ? null
                  : _resendOtp,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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

class _OtpCodeField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller.text,
      validator: (_) => validator(controller.text),
      autovalidateMode:
          AutovalidateMode.onUserInteraction,
      builder: (field) {
        final otp = controller.text;
        final activeIndex = otp.length.clamp(0, 5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled
                  ? () {
                      focusNode.requestFocus();
                    }
                  : null,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;

                  final calculatedWidth =
                      (constraints.maxWidth -
                              (spacing * 5)) /
                          6;

                  final boxWidth =
                      calculatedWidth.clamp(42.0, 52.0);

                  return Stack(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) {
                            final hasValue =
                                index < otp.length;

                            final isActive =
                                focusNode.hasFocus &&
                                    index == activeIndex &&
                                    otp.length < 6;

                            final character = hasValue
                                ? otp[index]
                                : '';

                            return AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 180,
                              ),
                              curve: Curves.easeOut,
                              width: boxWidth,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hasValue
                                    ? AppTheme.primaryTeal
                                        .withOpacity(0.07)
                                    : const Color(0xFFF7FAFA),
                                borderRadius:
                                    BorderRadius.circular(15),
                                border: Border.all(
                                  color: field.hasError
                                      ? AppTheme.errorRed
                                      : isActive || hasValue
                                          ? AppTheme.primaryTeal
                                          : const Color(
                                              0xFFDCE7E7,
                                            ),
                                  width: isActive
                                      ? 1.8
                                      : 1.2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme
                                              .primaryTeal
                                              .withOpacity(0.13),
                                          blurRadius: 12,
                                          offset:
                                              const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 180,
                                ),
                                child: Text(
                                  character,
                                  key: ValueKey(character),
                                  style: const TextStyle(
                                    color: AppTheme
                                        .textDarkPrimary,
                                    fontSize: 23,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.01,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            enabled: enabled,
                            autofocus: true,
                            keyboardType:
                                TextInputType.number,
                            textInputAction:
                                TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.oneTimeCode,
                            ],
                            maxLength: 6,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(
                                6,
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              field.didChange(value);
                              onChanged(value);
                            },
                            onSubmitted: onSubmitted,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            if (field.hasError) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.errorRed,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      field.errorText ?? 'Invalid OTP',
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _FloatingCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(
            opacity + 0.03,
          ),
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: AppTheme.primaryTeal,
          ),
          SizedBox(width: 7),
          Flexible(
            child: Text(
              'Protected by secure OTP verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}