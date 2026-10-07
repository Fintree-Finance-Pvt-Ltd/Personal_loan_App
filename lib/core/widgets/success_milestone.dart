import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// A polished fintech success milestone animation.
/// Uses an animated expanding emerald ring, checkmark draw/scale, and clean messaging.
class SuccessMilestoneView extends StatefulWidget {
  final String title;
  final String message;
  final String? primaryCtaText;
  final VoidCallback? onPrimaryCta;
  final Widget? extraContent;

  const SuccessMilestoneView({
    super.key,
    required this.title,
    required this.message,
    this.primaryCtaText,
    this.onPrimaryCta,
    this.extraContent,
  });

  @override
  State<SuccessMilestoneView> createState() => _SuccessMilestoneViewState();
}

class _SuccessMilestoneViewState extends State<SuccessMilestoneView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated checkmark emblem
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.successBg,
                border: Border.all(
                  color: AppTheme.successGreen.withValues(alpha: 0.35),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: ScaleTransition(
                  scale: _checkAnimation,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 46,
                    color: AppTheme.successGreen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDarkPrimary,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textDarkSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.extraContent != null) ...[
                  const SizedBox(height: 20),
                  widget.extraContent!,
                ],
                if (widget.primaryCtaText != null && widget.onPrimaryCta != null) ...[
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: widget.onPrimaryCta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        widget.primaryCtaText!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
