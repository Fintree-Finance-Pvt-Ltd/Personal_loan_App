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
  late final AnimationController _backgroundController;
  late final AnimationController _loaderController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  String? _errorMessage;
  bool _isSyncing = true;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.05,
        1,
        curve: Curves.easeOut,
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.55,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0,
          0.7,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.22),
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
    _syncCustomerState();
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
        ref
            .read(journeyControllerProvider.notifier)
            .syncCustomerState(),

        // Ensures the splash animation remains visible briefly.
        Future<void>.delayed(
          const Duration(milliseconds: 1600),
        ),
      ]);

      if (!mounted) return;

      final targetRoute =
          ref.read(journeyControllerProvider).targetRoute;

      context.go(targetRoute);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSyncing = false;
        _errorMessage =
            'We could not restore your session. Please check your connection and try again.';
      });
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _backgroundController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final logoSize = (screenSize.width * 0.27)
        .clamp(98.0, 126.0)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF043D43),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF033A42),
                    Color(0xFF007C78),
                    Color(0xFF0BA99B),
                  ],
                  stops: [
                    0,
                    0.58,
                    1,
                  ],
                ),
              ),
            ),
          ),

          _buildAnimatedBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 22,
              ),
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: _SecurityBadge(),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: SlideTransition(
                        position: _contentSlideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAnimatedLogo(logoSize),

                              const SizedBox(height: 30),

                              const Text(
                                'Personal Loan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'Simple. Secure. Completely digital.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 15,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 38),

                              AnimatedSwitcher(
                                duration:
                                    const Duration(milliseconds: 300),
                                child: _errorMessage != null
                                    ? _buildErrorCard()
                                    : _buildLoadingSection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color: Colors.white.withOpacity(0.78),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Secure digital lending experience',
                              style: TextStyle(
                                color:
                                    Colors.white.withOpacity(0.74),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 9),

                        Text(
                          'Powered by Fintree Finance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final movement = _backgroundController.value;

        return Stack(
          children: [
            Positioned(
              top: -70 + (movement * 22),
              right: -75,
              child: const _FloatingShape(
                size: 220,
                opacity: 0.07,
              ),
            ),

            Positioned(
              top: 190 - (movement * 20),
              left: -85,
              child: const _FloatingShape(
                size: 175,
                opacity: 0.055,
              ),
            ),

            Positioned(
              bottom: 55 + (movement * 18),
              right: -45,
              child: const _FloatingShape(
                size: 140,
                opacity: 0.065,
              ),
            ),

            Positioned(
              top: 145 + (movement * 12),
              right: 55,
              child: const _FloatingShape(
                size: 38,
                opacity: 0.11,
              ),
            ),

            Positioned(
              bottom: 210 - (movement * 10),
              left: 50,
              child: const _FloatingShape(
                size: 26,
                opacity: 0.09,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLogo(double logoSize) {
    return ScaleTransition(
      scale: _logoScaleAnimation,
      child: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          final scale =
              1 + (_backgroundController.value * 0.035);

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: logoSize + 34,
              height: logoSize + 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),

            Container(
              width: logoSize + 14,
              height: logoSize + 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
            ),

            Container(
              width: logoSize,
              height: logoSize,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 35,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Image.asset(
                'lib/assets/images/Logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.account_balance_rounded,
                    size: 54,
                    color: AppTheme.primaryTeal,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      key: const ValueKey('loading-section'),
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 330,
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _loaderController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle:
                        _loaderController.value * 6.283185307,
                    child: child,
                  );
                },
                child: Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.13),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.6,
                    backgroundColor: Color(0x44FFFFFF),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preparing your journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Restoring your secure session...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 4,
              color: Colors.white.withOpacity(0.12),
              child: AnimatedBuilder(
                animation: _loaderController,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Align(
                        alignment: Alignment(
                          -1 +
                              (_loaderController.value * 2),
                          0,
                        ),
                        child: Container(
                          width: constraints.maxWidth * 0.34,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.white.withOpacity(0.4),
                                blurRadius: 7,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      key: const ValueKey('error-section'),
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 350,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.errorBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.errorRed,
              size: 24,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Unable to continue',
            style: TextStyle(
              color: AppTheme.textDarkPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textDarkSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _isSyncing ? null : _syncCustomerState,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
              ),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            'Secure & encrypted',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingShape extends StatelessWidget {
  final double size;
  final double opacity;

  const _FloatingShape({
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
          color: Colors.white.withOpacity(
            opacity + 0.025,
          ),
        ),
      ),
    );
  }
}