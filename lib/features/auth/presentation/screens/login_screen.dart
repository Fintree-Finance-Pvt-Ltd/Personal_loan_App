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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _consentGiven = true;
  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Big Finley Brand Logo (From Web)
                      _buildBigLogo(),

                      // 2. Hero Graphic Frame with signature web curved corner
                      _buildHeroImageFrame(),

                      const SizedBox(height: 8),

                          // Heading
                          const Text(
                            'Sign In With',
                            style: TextStyle(
                              color: AppTheme.textDarkPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter your mobile number to receive a secure OTP.',
                            style: TextStyle(
                              color: AppTheme.textDarkSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Mobile Number Label
                          const Text(
                            'Mobile Number',
                            style: TextStyle(
                              color: AppTheme.textDarkPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Single Unified Border Input (No nested boxes)
                          _buildCleanInputField(state.isLoading),

        

                          const SizedBox(height: 22),

                          // Trust Badges: RBI Approved & Active Borrowers
                          _buildTrustBadgesRow(),

                          const SizedBox(height: 20),

                          // Consent Agreement Tile
                          _buildConsentCheckbox(state.isLoading),

                          // Error Message Display
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorBanner(state.errorMessage!),
                          ],

                          const SizedBox(height: 24),

                          // Request OTP Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: AppButton(
                              text: 'Request OTP',
                              isLoading: state.isLoading,
                              onPressed: _submit,
                              icon: Icons.arrow_forward_rounded,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Regulatory Copyright
                          Center(
                            child: Text(
                              '© ${DateTime.now().year} Finley Finance Private Limited. All rights reserved.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Big FinLeaf / Finley Logo matching the website header
  Widget _buildBigLogo() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'lib/assets/images/IMG_0007-removebg-preview.png',
        height: 75,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildBrandHeader(),
      ),
    );
  }

  /// Hero Image frame matching web design with asymmetric curved corners
  Widget _buildHeroImageFrame() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(80),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(80),
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        child: Image.asset(
          'lib/assets/images/DSC_7504-4_copy_v_n.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.primaryTeal,
            child: const Center(
              child: Icon(Icons.image, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'lib/assets/images/Logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.spa_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finley',
              style: TextStyle(
                color: AppTheme.textDarkPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            Text(
              'DIGITAL PERSONAL LOANS',
              style: TextStyle(
                color: AppTheme.primaryTeal,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCleanInputField(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isInputFocused ? AppTheme.primaryTeal : AppTheme.borderLight,
          width: _isInputFocused ? 1.5 : 1.1,
        ),
        boxShadow: _isInputFocused
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Text('🇮🇳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text(
            '+91',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDarkPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 22,
            color: AppTheme.borderLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _mobileController,
              focusNode: _mobileFocusNode,
              enabled: !isLoading,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 10,
              validator: Validators.validateMobile,
              onFieldSubmitted: (_) => _submit(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _MobileNumberAutofillFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              style: const TextStyle(
                color: AppTheme.textDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                counterText: '',
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgesRow() {
    return Row(
      children: [
        Expanded(
          child: _buildTrustBadge(
            icon: Icons.account_balance_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            title: 'RBI Approved',
            subtitle: 'Powered by NBFC',
          ),
        ),
        const SizedBox(width: 12),
        // Expanded(
        //   child: _buildTrustBadge(
        //     icon: Icons.groups_rounded,
        //     iconBg: const Color(0xFFEDE9FE),
        //     iconColor: const Color(0xFF7C3AED),
        //     title: '10 Lakh+',
        //     subtitle: 'Active Borrowers',
        //   ),
        // ),
      ],
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderMuted),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDarkPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCheckbox(bool isLoading) {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              setState(() {
                _consentGiven = !_consentGiven;
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: _consentGiven,
              activeColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: isLoading
                  ? null
                  : (val) {
                      setState(() {
                        _consentGiven = val ?? false;
                      });
                    },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to Finley\'s ',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textDarkSecondary,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' and acknowledge the '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppTheme.errorRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorDarkRed,
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

class _MobileNumberAutofillFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

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