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
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  String? _errorMessage;
  bool _isSyncing = true;
  int _statusStepIndex = 0;

  static const List<String> _securitySteps = [
    'Verifying secure channel...',
    'Authenticating profile...',
    'Preparing your dashboard...',
  ];

  @override
  void initState() {
    super.initState();

    // Set immersive light-on-dark system navigation
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.primaryDeepTeal,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _startStatusSequence();
    _syncCustomerState();
  }

  void _startStatusSequence() async {
    for (int i = 0; i < _securitySteps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted && _isSyncing && _errorMessage == null) {
        setState(() => _statusStepIndex = i);
      }
    }
  }

  Future<void> _syncCustomerState() async {
    if (mounted) {
      setState(() {
        _isSyncing = true;
        _errorMessage = null;
      });
    }

    try {
      await Future.wait<void>([
        ref.read(journeyControllerProvider.notifier).syncCustomerState(),
        Future<void>.delayed(const Duration(milliseconds: 2100)),
      ]);

      if (!mounted) return;
      final targetRoute = ref.read(journeyControllerProvider).targetRoute;
      context.go(targetRoute);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _errorMessage =
            'Unable to establish a secure connection. Please verify your network.';
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.primaryDeepTeal,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Elegant dark ambient backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryDeepTeal,
                    AppTheme.primaryDeepTeal.withValues(alpha: 0.96),
                    const Color(0xFF031614),
                  ],
                ),
              ),
            ),
          ),

          // Soft central radial bloom
          Positioned(
            top: size.height * 0.28,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentMint.withValues(alpha: 0.08),
                    AppTheme.primaryTeal.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top discreet accreditation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
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

                // Bottom State Loader & Regulatory Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _errorMessage != null
                            ? _buildErrorPanel()
                            : _buildProgressStatus(),
                      ),
                      const SizedBox(height: 28),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 11,
            color: AppTheme.accentMint.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 5),
          Text(
            'BANK-GRADE SECURITY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandMark() {
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppTheme.accentMint.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -4,
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
            color: AppTheme.primaryDeepTeal,
            size: 44,
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
          'Finley',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'INSTANT DIGITAL CREDIT',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.accentMint.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStatus() {
    return Column(
      key: const ValueKey('normal-loader'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sleek micro progress track
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 130,
            height: 2.5,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentMint),
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _securitySteps[_statusStepIndex],
            key: ValueKey<int>(_statusStepIndex),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel() {
    return Container(
      key: const ValueKey('error-card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF142422),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFFFA280),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage ?? 'Network unreachable.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: TextButton(
              onPressed: _isSyncing ? null : _syncCustomerState,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tap to Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstitutionalFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'LENDING PARTNER',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Fintree Finance (RBI Reg. NBFC)',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}