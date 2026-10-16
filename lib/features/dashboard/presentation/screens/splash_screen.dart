import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../journey_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _pulseGlowAnimation;

  int _statusStepIndex = 0;

  static const List<String> _securitySteps = [
    'Verifying secure channel...',
    'Authenticating profile...',
    'Preparing your dashboard...',
  ];

  @override
  void initState() {
    super.initState();

    // Set clean light system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Main entrance orchestration
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle ambient breathing pulse for the brand icon halo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseScaleAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _pulseGlowAnimation = Tween<double>(begin: 0.12, end: 0.28).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entranceController.forward();
    _startStatusSequence();
    _syncCustomerState();
  }

  void _startStatusSequence() async {
    for (int i = 0; i < _securitySteps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        setState(() => _statusStepIndex = i);
      }
    }
  }

  Future<void> _syncCustomerState() async {
    try {
      await Future.wait<void>([
        ref
            .read(journeyControllerProvider.notifier)
            .syncCustomerState()
            .catchError((_) {}),
        Future<void>.delayed(const Duration(milliseconds: 2200)),
      ]);
    } catch (_) {
      // Continue automatically without blocking the user
    }

    if (!mounted) return;
    final targetRoute = ref.read(journeyControllerProvider).targetRoute;
    context.go(targetRoute.isNotEmpty ? targetRoute : '/login');
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Pristine multi-layer canvas backdrop
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFFAFCFA),
                    Color(0xFFF4F9F6),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Central ambient emerald halo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Positioned(
                top: size.height * 0.24,
                child: Transform.scale(
                  scale: _pulseScaleAnimation.value,
                  child: Container(
                    width: size.width * 0.85,
                    height: size.width * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentMint.withValues(
                            alpha: _pulseGlowAnimation.value,
                          ),
                          AppTheme.primaryTeal.withValues(
                            alpha: _pulseGlowAnimation.value * 0.35,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Trust & Security Pill Badge
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: _buildTopTrustTag(),
                  ),
                ),

                // Centered Brand Focus
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildBrandMark(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildBrandTypography(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom State Loader & Institutional Regulatory Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProgressStatus(),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildInstitutionalFooter(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTrustTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightTeal,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 13,
            color: AppTheme.primaryTeal,
          ),
          SizedBox(width: 6),
          Text(
            'BANK-GRADE 256-BIT ENCRYPTION',
            style: TextStyle(
              color: AppTheme.primaryDarkTeal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandMark() {
    return Container(
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.borderLight.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'lib/assets/images/Logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.primaryTeal,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandTypography() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Fin-Tree',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textDarkPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 1.5,
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'INSTANT DIGITAL CREDIT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryTeal,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 1.5,
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStatus() {
    return Column(
      key: const ValueKey('normal-loader'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sleek Minimalist Progress Capsule
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: const SizedBox(
            width: 130,
            height: 3.5,
            child: LinearProgressIndicator(
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Live verification status with breathing pulse indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryTeal,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withValues(
                          alpha: _pulseController.value * 0.45,
                        ),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                _securitySteps[_statusStepIndex],
                key: ValueKey<int>(_statusStepIndex),
                style: const TextStyle(
                  color: AppTheme.textDarkSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstitutionalFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'LENDING PARTNER',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3.5,
          height: 3.5,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.borderLight,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Fintree Finance (RBI Reg. NBFC)',
          style: TextStyle(
            color: AppTheme.textDarkSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}