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

  late final AnimationController _introController;
  late final AnimationController _floatingController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  bool _consentGiven = true;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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

    _logoScaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0,
          0.65,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.25,
          1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    _introController.dispose();
    _floatingController.dispose();
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

    final heroHeight = (screenSize.height * 0.39).clamp(
      285.0,
      355.0,
    );

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
                        : 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: heroHeight,
                          child: _buildHeroSection(),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: SlideTransition(
                            position: _cardSlideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildLoginCard(state),
                            ),
                          ),
                        ),

                        Transform.translate(
                          offset: const Offset(0, -8),
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

  Widget _buildHeroSection() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/Girl_1.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF063B43),
                      Color(0xFF008B86),
                      Color(0xFF15B8A6),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x7A002D33),
                  Color(0xC9003238),
                  Color(0xF2073439),
                ],
              ),
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
                  top: 20 + (value * 12),
                  right: -30,
                  child: const _FloatingOrb(
                    size: 130,
                    opacity: 0.10,
                  ),
                ),
                Positioned(
                  top: 145 - (value * 10),
                  left: -40,
                  child: const _FloatingOrb(
                    size: 105,
                    opacity: 0.08,
                  ),
                ),
                Positioned(
                  top: 100 + (value * 7),
                  right: 75,
                  child: const _FloatingOrb(
                    size: 34,
                    opacity: 0.13,
                  ),
                ),
              ],
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            22,
            24,
            48,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Container(
                    height: 62,
                    constraints: const BoxConstraints(
                      minWidth: 62,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.account_balance_rounded,
                          color: AppTheme.primaryTeal,
                          size: 34,
                        );
                      },
                    ),
                  ),
                ),

                const Spacer(),

                const Text(
                  'Simple loans.\nSmarter possibilities.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Apply securely and continue your personal loan journey in just a few steps.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 18),

                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrustPill(
                      icon: Icons.verified_user_outlined,
                      text: 'Secure',
                    ),
                    _TrustPill(
                      icon: Icons.description_outlined,
                      text: 'Paperless',
                    ),
                    _TrustPill(
                      icon: Icons.bolt_rounded,
                      text: 'Quick',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(dynamic state) {
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
          color: const Color(0xFFE2EEEE),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063B43).withOpacity(0.10),
            blurRadius: 34,
            spreadRadius: 1,
            offset: const Offset(0, 14),
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
                'Welcome back',
                style: TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Enter your registered mobile number and we will send you a secure verification OTP.',
                style: TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Mobile number',
                style: TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              TextFormField(
                controller: _mobileController,
                focusNode: _mobileFocusNode,
                enabled: !state.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [
                  AutofillHints.telephoneNumber,
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
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(
                  color: AppTheme.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 10-digit mobile number',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9BA9AC),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F9F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(
                      left: 6,
                      right: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Color(0xFFDDE7E8),
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
                        SizedBox(width: 7),
                        Text(
                          '+91',
                          style: TextStyle(
                            color: AppTheme.textDarkPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFDDE8E8),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryTeal,
                      width: 1.6,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.errorRed,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.errorRed,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 17),

              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: state.isLoading
                    ? null
                    : () {
                        setState(() {
                          _consentGiven = !_consentGiven;
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    10,
                    12,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: _consentGiven
                        ? AppTheme.primaryTeal.withOpacity(0.06)
                        : const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _consentGiven
                          ? AppTheme.primaryTeal.withOpacity(0.25)
                          : const Color(0xFFE2E9E9),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Checkbox(
                          value: _consentGiven,
                          activeColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF9CAEB0),
                            width: 1.4,
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
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: AppTheme.textDarkSecondary,
                                fontSize: 12,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'I consent to receiving OTP and '
                                      'loan-related communication and agree '
                                      'to the ',
                                ),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: AppTheme.primaryTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: ' for Personal Loan processing.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: state.errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(state.errorMessage),
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.errorRed.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Get Verification OTP',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF7B8F91),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your information is encrypted and protected',
                    style: TextStyle(
                      color: const Color(0xFF567073).withOpacity(0.9),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
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
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _FloatingOrb({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
        border: Border.all(
          color: Colors.white.withOpacity(opacity + 0.04),
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 16,
            color: AppTheme.primaryTeal,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              'Secure digital lending experience',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textDarkSecondary.withOpacity(0.9),
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