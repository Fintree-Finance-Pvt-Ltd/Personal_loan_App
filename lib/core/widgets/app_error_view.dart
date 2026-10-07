import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'app_button.dart';

/// Polished error card that presents customer-friendly error states
/// with subtle entrance animation and retry actions without exposing technical errors.
class AppErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.title = 'Unable to Complete Request',
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.icon = Icons.error_outline_rounded,
  });

  /// Sanitizes technical exception messages into clear customer-friendly messages
  static String formatUserFriendlyMessage(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Something unexpected occurred. Please check your connection and try again.';
    }
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') || lower.contains('network') || lower.contains('connection')) {
      return 'We could not reach the loan server. Please verify your internet connection and try again.';
    }
    if (lower.contains('timeout')) {
      return 'The request took a little too long to respond. Please try again in a moment.';
    }
    if (lower.contains('500') || lower.contains('internal server')) {
      return 'The service is temporarily unavailable. Our team is on it—please retry shortly.';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Your session has expired. Please log in again to continue your loan journey.';
    }
    if (lower.startsWith('exception: ')) {
      return raw.substring(11);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final cleanMessage = formatUserFriendlyMessage(message);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorRed.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.errorBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDarkPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                cleanMessage,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textDarkSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 22),
                AppButton(
                  text: retryText,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  height: 46,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
