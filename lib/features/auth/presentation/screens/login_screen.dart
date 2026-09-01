import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();

  // Entrance and loop controllers
  late final AnimationController _entranceController;
  late final AnimationController _floatController;
  late final AnimationController _pulseGlowController;

  // Staggered entrance animations
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _formFadeAnimation;
  late final Animation<Offset> _formSlideAnimation;
  late final Animation<double> _footerFadeAnimation;

  bool _consentGiven = true;
  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _pulseGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Staggered Timeline:
    // 0.0 - 0.5: Logo scale & slide
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // 0.3 - 0.85: Form card slide & fade
    _formFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOut),
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 0.6 - 1.0: Security footer fade
    _footerFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _mobileFocusNode.addListener(() {
      setState(() {
        _isInputFocused = _mobileFocusNode.hasFocus;
      });
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    _entranceController.dispose();
    _floatController.dispose();
    _pulseGlowController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept customer consent to proceed.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(
          _mobileController.text.trim(),
          _consentGiven,
        );

    if (success && mounted) {
      context.push('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Subtle Animated Ambient Background Glows
          _buildAmbientMeshBackground(screenSize),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: mediaQuery.viewInsets.bottom > 0
                        ? mediaQuery.viewInsets.bottom + 16
                        : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),

                          // ==========================================
                          // ANIMATED LARGE LOGO HEADER
                          // ==========================================
                          SlideTransition(
                            position: _logoSlideAnimation,
                            child: ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: _buildLargeLogoHeader(),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ==========================================
                          // ANIMATED FORM CARD
                          // ==========================================
                          SlideTransition(
                            position: _formSlideAnimation,
                            child: FadeTransition(
                              opacity: _formFadeAnimation,
                              child: _buildFormCard(state),
                            ),
                          ),

                          const Spacer(),

                          const SizedBox(height: 24),

                          // ==========================================
                          // ANIMATED TRUST & SECURITY FOOTER
                          // ==========================================
                          FadeTransition(
                            opacity: _footerFadeAnimation,
                            child: const _SecurityFooter(),
                          ),
                        ],
                      ),
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

  /// Ambient fintech glow spheres floating softly behind the layout
  Widget _buildAmbientMeshBackground(Size size) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        final t = _floatController.value;
        return Stack(
          children: [
            // Top Right Soft Emerald Bloom
            Positioned(
              top: -60 + (t * 20),
              right: -50 + (t * 15),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentMint.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Mid Left Deep Royal Blue Aura
            Positioned(
              top: size.height * 0.38 - (t * 25),
              left: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.secondaryLightBlue.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLargeLogoHeader() {
    return Column(
      children: [
        // Floating Logo Card with Ambient Pulse Glow
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offsetY = math.sin(_floatController.value * math.pi) * -5;
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: child,
            );
          },
          child: AnimatedBuilder(
            animation: _pulseGlowController,
            builder: (context, child) {
              final glowAlpha = 0.05 + (_pulseGlowController.value * 0.07);
              return Container(
                height: 114,
                width: 228,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _isInputFocused
                        ? AppTheme.accentCyan.withValues(alpha: 0.45)
                        : AppTheme.borderLight,
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: glowAlpha),
                      blurRadius: 32,
                      spreadRadius: 3,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: AppTheme.accentCyan.withValues(alpha: glowAlpha * 0.8),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              );
            },
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
                      'FINLE',
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 26),

        // Shimmering Gradient Headline
        AnimatedBuilder(
          animation: _pulseGlowController,
          builder: (context, child) {
            final shift = _pulseGlowController.value;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: const [
                  AppTheme.primaryTeal,
                  AppTheme.accentCyan,
                  AppTheme.secondaryBlue,
                ],
                stops: [
                  0.0,
                  (0.4 + (shift * 0.3)).clamp(0.0, 1.0),
                  1.0,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: child,
            );
          },
          child: const Text(
            'Finle Se Loan Le',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Enter your registered mobile number to receive a secure login OTP',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textDarkSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(dynamic state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isInputFocused
              ? AppTheme.primaryTeal.withValues(alpha: 0.4)
              : AppTheme.borderLight,
          width: _isInputFocused ? 1.4 : 1.0,
        ),
        boxShadow: _isInputFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mobile Number',
                    style: TextStyle(
                      color: AppTheme.textDarkPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_isInputFocused)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Active',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _mobileController,
                focusNode: _mobileFocusNode,
                enabled: !state.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [
                  AutofillHints.telephoneNumber,
                  AutofillHints.telephoneNumberNational,
                  AutofillHints.username,
                ],
                maxLength: 10,
                validator: Validators.validateMobile,
                onFieldSubmitted: (_) {
                  if (!state.isLoading) {
                    _submit();
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _MobileNumberAutofillFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 10-digit number',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: _isInputFocused
                      ? AppTheme.primarySoftTeal
                      : AppTheme.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 6, right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: AppTheme.borderLight,
                          width: 1.2,
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🇮🇳',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '+91',
                          style: TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Animated Consent Card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: state.isLoading
                    ? null
                    : () {
                        setState(() {
                          _consentGiven = !_consentGiven;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _consentGiven
                        ? AppTheme.primaryLightTeal.withValues(alpha: 0.7)
                        : AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _consentGiven
                          ? AppTheme.primaryTeal.withValues(alpha: 0.35)
                          : AppTheme.borderMuted,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _consentGiven,
                          activeColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          onChanged: state.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _consentGiven = value == true;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: AppTheme.textDarkSecondary,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'I agree to receive verification OTP and accept the ',
                              ),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' for processing.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Animated Error State Banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      child: child,
                    ),
                  );
                },
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

              // Animated Submit Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Get Verification OTP',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
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

class _MobileNumberAutofillFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    // Handle country code prefixes from mobile autofill (+91, 91, 0)
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    } else if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}