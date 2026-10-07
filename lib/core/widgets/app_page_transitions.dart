import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Provides unified, subtle, and premium page transitions across the entire
/// personal loan application. Uses fade + slight horizontal slide + subtle scale (0.98 -> 1.0)
/// with 260ms duration and easeOutCubic curve, respecting accessibility reduced motion.
CustomTransitionPage<T> buildAppPageTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 260),
  Duration reverseDuration = const Duration(milliseconds: 220),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
      // Respect accessibility settings for reduced motion
      final bool disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        return childWidget;
      }

      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Subtle fade from 0.0 to 1.0
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

      // Very subtle horizontal slide (only 3% from the right) for continuity
      final slide = Tween<Offset>(
        begin: const Offset(0.03, 0.0),
        end: Offset.zero,
      ).animate(curvedAnimation);

      // Subtle scale 0.985 -> 1.0
      final scale = Tween<double>(
        begin: 0.985,
        end: 1.0,
      ).animate(curvedAnimation);

      // Secondary exit animation: slight fade out and scale down for the exiting screen
      final secondaryCurved = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final secondaryFade = Tween<double>(begin: 1.0, end: 0.92).animate(secondaryCurved);
      final secondaryScale = Tween<double>(begin: 1.0, end: 0.985).animate(secondaryCurved);

      return FadeTransition(
        opacity: secondaryFade,
        child: ScaleTransition(
          scale: secondaryScale,
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                child: childWidget,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Helper for modal/bottom-up transitions (like review, terms, or document viewers)
CustomTransitionPage<T> buildAppModalTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, childWidget) {
      final bool disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        return childWidget;
      }

      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 0.06),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: childWidget,
        ),
      );
    },
  );
}
