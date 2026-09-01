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
  late final AnimationController _introController;
  late final AnimationController _radarController;
  late final AnimationController _scanController;
  late final AnimationController _floatController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _textSlideAnimation;

  String? _errorMessage;
  bool _isSyncing = true;
  int _securityStepIndex = 0;

  static const List<String> _securitySteps = [
    'Verifying Security...',
    'Authenticating Session...',
    'Loading Personal Loan Portal...',
  ];

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Continuous glowing radar pulse expansion
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Holographic sweep / spinner
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scanController.addListener(_onScanTick);

    // Subtle 3D crest hover float
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _introController.forward();
    _syncCustomerState();
  }

  void _onScanTick() {
    final step = (_scanController.value * _securitySteps.length).floor() %
        _securitySteps.length;
    if (step != _securityStepIndex && mounted) {
      setState(() => _securityStepIndex = step);
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
            'We could not verify your connection. Please check your internet and try again.';
      });
    }
  }

  @override
  void dispose() {
    _scanController.removeListener(_onScanTick);
    _introController.dispose();
    _radarController.dispose();
    _scanController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Expansive logo crest footprint (38% to 48% of screen width)
    final heroCrestSize = (screenSize.width * 0.44).clamp(160.0, 205.0);

    return Scaffold(
      backgroundColor: const Color(0xFF032B2B),
      body: Stack(
        children: [
          // Background Gradient matching the fintech emerald reference
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF022629),
                    Color(0xFF04383B),
                    Color(0xFF03262A),
                  ],
                  stops: [0.0, 0.52, 1.0],
                ),
              ),
            ),
          ),

          // Central Radial Ambient Glow behind the logo
          Positioned.fill(
            child: Center(
              child: Container(
                width: screenSize.width * 0.95,
                height: screenSize.width * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentCyan.withValues(alpha: 0.18),
                      AppTheme.accentMint.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top Right Security Badge
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: _TopSecurityBadge(),
                    ),
                  ),

                  // Center Hero Logo Crest & Typography
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hero Shield Crest with Radar Rings
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                final floatY = math.sin(_floatController.value * math.pi) * -6;
                                return Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: child,
                                );
                              },
                              child: _buildHeroLogoCrest(heroCrestSize),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Brand Typography
                          SlideTransition(
                            position: _textSlideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                children: [
                                  const Text(
                                    'Finle',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'PERSONAL LOANS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 38),

                          // Dynamic Holographic Scanner / Error Card
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            child: _errorMessage != null
                                ? _buildErrorBottomSheet()
                                : _buildHolographicRadarScanner(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom "POWERED BY FINTREE FINANCE"
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildBottomPoweredBy(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Prominent, high-impact Logo Shield Crest surrounded by concentric radar waves
  Widget _buildHeroLogoCrest(double size) {
    return SizedBox(
      width: size + 80,
      height: size + 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Radiating Radar Waves
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(size + 80, size + 80),
                painter: _RadarWavesPainter(
                  progress: _radarController.value,
                  baseColor: AppTheme.accentMint,
                ),
              );
            },
          ),

          // Outer Emerald Holographic Glow Ring
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accentMint.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentCyan.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Emerald Glass Shield & Embossed Logo Container
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.25, -0.35),
                radius: 0.9,
                colors: [
                  const Color(0xFF1BE5B5).withValues(alpha: 0.25),
                  const Color(0xFF034D48).withValues(alpha: 0.85),
                  const Color(0xFF022A2B),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF4EECD0).withValues(alpha: 0.65),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppTheme.accentCyan.withValues(alpha: 0.30),
                  blurRadius: 30,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'lib/assets/images/Logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.shield_rounded,
                        size: 64,
                        color: AppTheme.primaryTeal,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Elliptical Holographic Scanner
  Widget _buildHolographicRadarScanner() {
    return Column(
      key: const ValueKey('scanner-active'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Step Text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(
            _securitySteps[_securityStepIndex],
            key: ValueKey<int>(_securityStepIndex),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3D Perspective Elliptical Holographic Spinner
        SizedBox(
          width: 190,
          height: 52,
          child: AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) {
              return CustomPaint(
                painter: _HolographicEllipsePainter(
                  rotationProgress: _scanController.value,
                  glowColor: AppTheme.accentMint,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Refined Error Card
  Widget _buildErrorBottomSheet() {
    return Container(
      key: const ValueKey('scanner-error'),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                        color: AppTheme.textDarkPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _errorMessage ?? 'Unable to connect to service.',
                      style: const TextStyle(
                        color: AppTheme.textDarkSecondary,
                        fontSize: 11.5,
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
            height: 44,
            child: FilledButton.icon(
              onPressed: _isSyncing ? null : _syncCustomerState,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry Connection',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Footer "POWERED BY FINTREE FINANCE"
  Widget _buildBottomPoweredBy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'POWERED BY',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    size: 11,
                    color: AppTheme.accentMint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'FINTREE FINANCE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Top Right Security Pill ("Secured by Fintree")
class _TopSecurityBadge extends StatelessWidget {
  const _TopSecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: Color(0xFF049E7C),
          ),
          SizedBox(width: 6),
          Text(
            'Secured by Fintree',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering concentric pulsing radar rings behind the main logo
class _RadarWavesPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  _RadarWavesPainter({
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    const ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = (maxRadius * 0.65) + (maxRadius * 0.35 * ringProgress);
      final alpha = (1.0 - ringProgress) * 0.38;

      final paint = Paint()
        ..color = baseColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for the bottom holographic 3D radar scanner ring
class _HolographicEllipsePainter extends CustomPainter {
  final double rotationProgress;
  final Color glowColor;

  _HolographicEllipsePainter({
    required this.rotationProgress,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final innerRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.58,
      height: size.height * 0.58,
    );

    // Inner subtle base ellipse
    final basePaint = Paint()
      ..color = glowColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawOval(innerRect, basePaint);

    // Outer subtle track ellipse
    final outerTrackPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(outerRect, outerTrackPaint);

    // Glowing orbital sweep arc on outer ellipse
    final sweepAngle = math.pi * 0.85;
    final startAngle = (rotationProgress * 2 * math.pi) - (sweepAngle / 2);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [
          glowColor.withValues(alpha: 0.0),
          glowColor.withValues(alpha: 0.95),
          Colors.white,
        ],
        stops: const [0.0, 0.8, 1.0],
        transform: GradientRotation(startAngle),
      ).createShader(outerRect);

    canvas.drawArc(outerRect, startAngle, sweepAngle, false, sweepPaint);

    // Small glowing head dot
    final headAngle = startAngle + sweepAngle;
    final dotX = center.dx + (outerRect.width / 2) * math.cos(headAngle);
    final dotY = center.dy + (outerRect.height / 2) * math.sin(headAngle);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 3.2, dotPaint);

    // Dot glow
    final dotGlowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(dotX, dotY), 6.0, dotGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _HolographicEllipsePainter oldDelegate) =>
      oldDelegate.rotationProgress != rotationProgress;
}