import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification_model.dart';
import '../models/customer_model.dart';
import '../models/post_approval_model.dart';
import '../services/push_notification_service.dart';
import '../storage/secure_storage_service.dart';
import '../utils/currency_utils.dart';
import '../../features/dashboard/presentation/journey_controller.dart';
import 'providers.dart';

class NotificationsState {
  final List<AppNotificationModel> items;
  final NotificationCategory activeFilter;
  final bool isLoaded;

  const NotificationsState({
    this.items = const [],
    this.activeFilter = NotificationCategory.all,
    this.isLoaded = false,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  List<AppNotificationModel> get filteredItems {
    if (activeFilter == NotificationCategory.all) return items;
    return items.where((n) => n.category == activeFilter).toList();
  }

  NotificationsState copyWith({
    List<AppNotificationModel>? items,
    NotificationCategory? activeFilter,
    bool? isLoaded,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final SecureStorageService _storage;
  StreamSubscription<AppNotificationModel>? _dynamicSub;

  NotificationsNotifier(this._storage) : super(const NotificationsState()) {
    _loadFromStorage();
    _dynamicSub = PushNotificationService.dynamicNotificationStream.listen((notification) {
      addNotification(notification);
    });
  }

  @override
  void dispose() {
    _dynamicSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.getStoredNotifications();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          state = state.copyWith(items: loaded, isLoaded: true);
          return;
        }
      }
    } catch (e) {
      debugPrint('[NotificationsNotifier] Error loading stored notifications: $e');
    }
    state = state.copyWith(isLoaded: true);
  }

  Future<void> _saveToStorage() async {
    try {
      final jsonList = state.items.map((n) => n.toJson()).toList();
      await _storage.saveStoredNotifications(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[NotificationsNotifier] Error saving notifications: $e');
    }
  }

  void addNotification(AppNotificationModel notif) {
    final exists = state.items.any((item) => item.id == notif.id);
    if (!exists) {
      final updated = [notif, ...state.items];
      updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(items: updated);
      _saveToStorage();
    }
  }

  void setFilter(NotificationCategory category) {
    state = state.copyWith(activeFilter: category);
  }

  void markAsRead(String id) {
    final updated = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
    _saveToStorage();
  }

  void markAllAsRead() {
    final updated = state.items.map((item) => item.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);
    _saveToStorage();
  }

  Future<void> deleteNotification(String id) async {
    final updated = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: updated);
    await _storage.addDismissedNotificationId(id);
    _saveToStorage();
  }

  Future<void> clearAll() async {
    for (final item in state.items) {
      await _storage.addDismissedNotificationId(item.id);
    }
    state = state.copyWith(items: []);
    _saveToStorage();
  }

  /// Synchronize real journey milestones from live API response
  /// completely free of dummy delays or static mock data.
  Future<void> syncRealMilestones(CustomerModel? customer, PostApprovalJourneyModel? postApproval) async {
    if (customer == null) return;
    final dismissed = await _storage.getDismissedNotificationIds();
    final lan = customer.latestLan ?? customer.platformLan ?? '';
    final appStatus = customer.latestApplicationStatus?.toUpperCase() ?? '';
    final loanStatus = customer.latestLoanStatus?.toUpperCase() ?? '';

    final isDisbursed = appStatus == 'DISBURSED' ||
        loanStatus == 'DISBURSED' ||
        postApproval?.workflow.currentStep == 'DISBURSED' ||
        postApproval?.loan.disbursalCompletedAt != null;

    if (isDisbursed && lan.isNotEmpty) {
      final loan = postApproval?.loan;
      final bank = postApproval?.bank;
      final num? rawAmt = loan?.disbursalAmount ?? loan?.approvedAmount ?? postApproval?.offer.approvedAmount;

      if (rawAmt != null && rawAmt > 0) {
        final disbursalId = 'real_disbursed_$lan';
        if (!dismissed.contains(disbursalId) && !state.items.any((n) => n.id == disbursalId)) {
          DateTime disbursalTime = DateTime.now();
          if (loan?.disbursalCompletedAt != null) {
            disbursalTime = DateTime.tryParse(loan!.disbursalCompletedAt!) ?? disbursalTime;
          } else if (loan?.disbursalDate != null) {
            disbursalTime = DateTime.tryParse(loan!.disbursalDate!) ?? disbursalTime;
          }

          final String bankDisplay = (bank?.bankName != null && bank?.accountMasked != null && bank!.accountMasked!.isNotEmpty)
              ? '${bank.bankName} (..${bank.accountMasked})'
              : (bank?.bankName ?? 'your registered bank account');

          addNotification(
            AppNotificationModel(
              id: disbursalId,
              title: 'Loan Disbursed Successfully! 🎉',
              body: '${CurrencyUtils.formatAmount(rawAmt.toDouble())} net amount credited to $bankDisplay.',
              category: NotificationCategory.loan,
              timestamp: disbursalTime,
              isRead: false,
              route: '/loan/$lan/loan-details',
              actionLabel: 'View RPS Schedule',
              utr: loan?.disbursalUtr,
              amount: rawAmt.toDouble(),
            ),
          );
        }
      }
    } else if (lan.isNotEmpty) {
      // Check if loan is approved
      final isApproved = loanStatus == 'APPROVED' ||
          appStatus == 'APPROVED' ||
          postApproval?.workflow.lenderApproved == true ||
          postApproval?.workflow.offerAccepted == true;

      if (isApproved) {
        final num? rawApproved = postApproval?.loan.approvedAmount ??
            postApproval?.offer.approvedAmount ??
            customer.assessmentFee?['totalAmount'];

        final approvedId = 'real_approved_$lan';
        if (!dismissed.contains(approvedId) && !state.items.any((n) => n.id == approvedId)) {
          final amountText = rawApproved != null && rawApproved > 0
              ? 'of ${CurrencyUtils.formatAmount(rawApproved.toDouble())} '
              : '';

          DateTime approvedTime = DateTime.now();
          if (postApproval?.loan.approvedAt != null) {
            approvedTime = DateTime.tryParse(postApproval!.loan.approvedAt!) ?? approvedTime;
          }

          addNotification(
            AppNotificationModel(
              id: approvedId,
              title: 'Loan Approved! 🎉',
              body: 'Your loan $amountText is approved and ready for bank disbursement.',
              category: NotificationCategory.offer,
              timestamp: approvedTime,
              isRead: false,
              route: '/loan/$lan/offer',
              actionLabel: 'View Loan Offer',
              amount: rawApproved?.toDouble(),
            ),
          );
        }

        // Check if mandate is pending
        final isMandatePending = postApproval != null &&
            postApproval.workflow.offerAccepted &&
            !postApproval.workflow.mandateCompleted;

        if (isMandatePending) {
          final mandateId = 'real_mandate_pending_$lan';
          if (!dismissed.contains(mandateId) && !state.items.any((n) => n.id == mandateId)) {
            addNotification(
              AppNotificationModel(
                id: mandateId,
                title: 'Setup Auto-Debit (e-Mandate) ⚡',
                body: 'Complete auto-debit setup to proceed with instant loan disbursal.',
                category: NotificationCategory.system,
                timestamp: DateTime.now(),
                isRead: false,
                route: '/loan/$lan/mandate',
                actionLabel: 'Setup Mandate',
              ),
            );
          }
        }

        // Check if eSign is pending
        final isEsignPending = postApproval != null &&
            postApproval.workflow.mandateCompleted &&
            !postApproval.workflow.esignCompleted;

        if (isEsignPending) {
          final esignId = 'real_esign_pending_$lan';
          if (!dismissed.contains(esignId) && !state.items.any((n) => n.id == esignId)) {
            addNotification(
              AppNotificationModel(
                id: esignId,
                title: 'Sign Loan Agreement ✍️',
                body: 'Digitally e-Sign your agreement to complete the loan approval journey.',
                category: NotificationCategory.system,
                timestamp: DateTime.now(),
                isRead: false,
                route: '/loan/$lan/esign',
                actionLabel: 'Sign Agreement',
              ),
            );
          }
        }
      }
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final notifier = NotificationsNotifier(storage);

  // Sync real milestones when live customer state loads
  ref.listen<JourneyState>(journeyControllerProvider, (previous, next) {
    if (!next.isLoading && next.customer != null) {
      notifier.syncRealMilestones(next.customer, next.postApproval);
    }
  });

  final journey = ref.read(journeyControllerProvider);
  if (!journey.isLoading && journey.customer != null) {
    notifier.syncRealMilestones(journey.customer, journey.postApproval);
  }

  return notifier;
});
