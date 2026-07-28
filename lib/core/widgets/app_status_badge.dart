import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppStatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            label ?? _formatStatusText(status),
            style: TextStyle(
              color: config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatusText(String text) {
    return text.replaceAll('_', ' ').toLowerCase().split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }

  _BadgeConfig _getStatusConfig(String status) {
    final upper = status.toUpperCase();
    if (upper.contains('APPROVED') ||
        upper.contains('VERIFIED') ||
        upper.contains('COMPLETED') ||
        upper.contains('SUCCESS') ||
        upper.contains('DISBURSED') ||
        upper.contains('ELIGIBLE')) {
      return _BadgeConfig(
        backgroundColor: AppTheme.successBg,
        textColor: AppTheme.successGreen,
        icon: Icons.check_circle_outline,
      );
    }
    if (upper.contains('PENDING') ||
        upper.contains('PROGRESS') ||
        upper.contains('SUBMITTED') ||
        upper.contains('PROCESSING') ||
        upper.contains('IN_PROGRESS')) {
      return _BadgeConfig(
        backgroundColor: AppTheme.warningBg,
        textColor: AppTheme.warningOrange,
        icon: Icons.access_time_rounded,
      );
    }
    if (upper.contains('REJECTED') ||
        upper.contains('FAILED') ||
        upper.contains('CANCELLED') ||
        upper.contains('INELIGIBLE') ||
        upper.contains('BLOCKED')) {
      return _BadgeConfig(
        backgroundColor: AppTheme.errorBg,
        textColor: AppTheme.errorRed,
        icon: Icons.cancel_outlined,
      );
    }
    return _BadgeConfig(
      backgroundColor: AppTheme.infoBg,
      textColor: AppTheme.infoBlue,
      icon: Icons.info_outline,
    );
  }
}

class _BadgeConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  _BadgeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
