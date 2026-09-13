import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  late final AnimationController _orbitalController;
  late final AnimationController _radarController;
  late final AnimationController _floatController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  String? _errorMessage;
  bool _isSyncing = true;
  int _statusStepIndex = 0;

  static const List<String> _securitySteps = [
    'Verifying Secure Gateway...',
    'Authenticating Device Profile...',
    'Loading Finley Portal...',
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _orbitalController.addListener(_onOrbitalTick);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _syncCustomerState();
  }

  void _onOrbitalTick() {
    final step = (_orbitalController.value * _securitySteps.length).floor() %
        _securitySteps.length;
    if (step != _statusStepIndex && mounted) {
      setState(() => _statusStepIndex = step);
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
        Future<void>.delayed(const Duration(milliseconds: 2200)),
      ]);

      if (!mounted) return;
      final targetRoute = ref.read(journeyControllerProvider).targetRoute;
      context.go(targetRoute);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSyncing = false;
        _errorMessage =
            'We could not verify your connection. Please check your network and try again.';
      });
    }
  }

  @override
  void dispose() {
    _orbitalController.removeListener(_onOrbitalTick);
    _entranceController.dispose();
    _orbitalController.dispose();
    _radarController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final crestSize = (screenSize.width * 0.42).clamp(150.0, 195.0);

    return Scaffold(
      backgroundColor: AppTheme.primaryDeepTeal,
      body: Stack(
        children: [
          // Background Gradient matching Finley Theme
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
          ),

          // Central Ambient Radial Glow
          Positioned(
            top: screenSize.height * 0.24,
            left: screenSize.width * 0.08,
            child: Container(
              width: screenSize.width * 0.84,
              height: screenSize.width * 0.84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentMint.withValues(alpha: 0.16),
                    AppTheme.primaryTeal.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.48, 1.0],
                ),
              ),
            ),
          ),

          // Floating Coin Accents
          Positioned(
            top: screenSize.height * 0.14,
            left: 28,
            child: _buildFloatingRupee(size: 38),
          ),
          Positioned(
            top: screenSize.height * 0.16,
            right: 28,
            child: _buildFloatingRupee(size: 46),
          ),
          Positioned(
            bottom: screenSize.height * 0.22,
            right: 32,
            child: _buildFloatingRupee(size: 34),
          ),
          Positioned(
            bottom: screenSize.height * 0.24,
            left: 36,
            child: _buildFloatingRupee(size: 30),
          ),

          // Foreground Information
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top Partner Pill
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: _TopPartnerBadge(),
                    ),
                  ),

                  // Center Hero Display
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                final floatY =
                                    math.sin(_floatController.value * math.pi) * -6;
                                return Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: child,
                                );
                              },
                              child: _buildHeroLogoCrest(crestSize),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Brand Typography
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  const Text(
                                    'Finley',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'DIGITAL PERSONAL LOANS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.accentMint.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 38),

                          // Radar / Error Display
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: _errorMessage != null
                                ? _buildErrorCard()
                                : _buildStatusIndicator(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Regulatory Strip
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBottomFooter(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLogoCrest(double size) {
    return SizedBox(
      width: size + 60,
      height: size + 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar ripples
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(size + 60, size + 60),
                painter: _RadarWavesPainter(
                  progress: _radarController.value,
                  baseColor: AppTheme.accentMint,
                ),
              );
            },
          ),

          // Outer halo
          Container(
            width: size + 14,
            height: size + 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentMint.withValues(alpha: 0.35),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCyan.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Logo card
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Image.asset(
              'lib/assets/images/Logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Icon(
                  Icons.spa_rounded,
                  color: AppTheme.primaryTeal,
                  size: 64,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      key: const ValueKey('status-normal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _securitySteps[_statusStepIndex],
            key: ValueKey<int>(_statusStepIndex),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 170,
          height: 38,
          child: AnimatedBuilder(
            animation: _orbitalController,
            builder: (context, _) {
              return CustomPaint(
                painter: _HolographicArcPainter(
                  progress: _orbitalController.value,
                  accentColor: AppTheme.accentMint,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      key: const ValueKey('status-error'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.errorBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppTheme.errorRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _errorMessage ?? 'Unable to connect to service.',
                      style: const TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : _syncCustomerState,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Retry Connection',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'POWERED BY ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 11,
                color: AppTheme.accentMint,
              ),
              SizedBox(width: 4),
              Text(
                'FINTREE FINANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingRupee({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFB300),
            Color(0xFFF57F17),
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '₹',
          style: TextStyle(
            color: const Color(0xFF5D4037),
            fontSize: size * 0.52,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TopPartnerBadge extends StatelessWidget {
  const _TopPartnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: AppTheme.primaryTeal,
          ),
          SizedBox(width: 5),
          Text(
            'RBI NBFC Partner',
            style: TextStyle(
              color: AppTheme.textDarkPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarWavesPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  _RadarWavesPainter({required this.progress, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i / 3)) % 1.0;
      final radius = (maxRadius * 0.6) + (maxRadius * 0.4 * ringProgress);
      final alpha = (1.0 - ringProgress) * 0.35;

      final paint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _HolographicArcPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  _HolographicArcPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    final trackPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(rect, trackPaint);

    final sweepAngle = math.pi * 0.8;
    final startAngle = (progress * 2 * math.pi) - (sweepAngle / 2);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = accentColor;

    canvas.drawArc(rect, startAngle, sweepAngle, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _HolographicArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}