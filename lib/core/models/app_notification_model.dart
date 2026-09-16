import 'package:flutter/material.dart';

enum NotificationCategory {
  all,
  loan,
  emi,
  offer,
  system,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? route;
  final String? actionLabel;
  final String? utr;
  final double? amount;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.route,
    this.actionLabel,
    this.utr,
    this.amount,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? route,
    String? actionLabel,
    String? utr,
    double? amount,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
      actionLabel: actionLabel ?? this.actionLabel,
      utr: utr ?? this.utr,
      amount: amount ?? this.amount,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  IconData get icon {
    switch (category) {
      case NotificationCategory.loan:
        return Icons.account_balance_wallet_rounded;
      case NotificationCategory.emi:
        return Icons.event_repeat_rounded;
      case NotificationCategory.offer:
        return Icons.local_offer_rounded;
      case NotificationCategory.system:
        return Icons.shield_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case NotificationCategory.loan:
        return const Color(0xFF10B981); // Emerald Green
      case NotificationCategory.emi:
        return const Color(0xFFF59E0B); // Amber Warning
      case NotificationCategory.offer:
        return const Color(0xFF8B5CF6); // Purple Accent
      case NotificationCategory.system:
        return const Color(0xFF3B82F6); // Blue Info
      default:
        return const Color(0xFF64748B);
    }
  }
}
