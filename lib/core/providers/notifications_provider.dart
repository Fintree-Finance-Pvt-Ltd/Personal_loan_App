import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/app_notification_model.dart';
import '../utils/currency_utils.dart';
import '../../features/dashboard/presentation/journey_controller.dart';
import '../models/customer_model.dart';
import '../models/post_approval_model.dart';
import '../services/push_notification_service.dart';

class NotificationsState {
  final List<AppNotificationModel> items;
  final NotificationCategory activeFilter;
  final bool isSeeded;

  const NotificationsState({
    this.items = const [],
    this.activeFilter = NotificationCategory.all,
    this.isSeeded = false,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  List<AppNotificationModel> get filteredItems {
    if (activeFilter == NotificationCategory.all) return items;
    return items.where((n) => n.category == activeFilter).toList();
  }

  NotificationsState copyWith({
    List<AppNotificationModel>? items,
    NotificationCategory? activeFilter,
    bool? isSeeded,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      isSeeded: isSeeded ?? this.isSeeded,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  StreamSubscription<AppNotificationModel>? _dynamicSub;

  NotificationsNotifier() : super(const NotificationsState()) {
    _dynamicSub = PushNotificationService.dynamicNotificationStream.listen((notification) {
      addNotification(notification);
    });
  }

  @override
  void dispose() {
    _dynamicSub?.cancel();
    super.dispose();
  }

  void addNotification(AppNotificationModel notif) {
    final exists = state.items.any((item) => item.id == notif.id);
    if (!exists) {
      final updated = [notif, ...state.items];
      updated.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(items: updated);
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
  }

  void markAllAsRead() {
    final updated = state.items.map((item) => item.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated);
  }

  void deleteNotification(String id) {
    final updated = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: updated);
  }

  void clearAll() {
    state = state.copyWith(items: []);
  }

  void seedForCustomer(CustomerModel? customer, PostApprovalJourneyModel? postApproval) {
    final lan = customer?.latestLan ?? customer?.platformLan ?? '';
    final appStatus = customer?.latestApplicationStatus?.toUpperCase() ?? '';
    final isDisbursed = appStatus == 'DISBURSED' ||
        customer?.latestLoanStatus == 'DISBURSED' ||
        postApproval?.workflow.currentStep == 'DISBURSED' ||
        postApproval?.loan.disbursalCompletedAt != null;

    final now = DateTime.now();

    List<AppNotificationModel> seededList = [];

    if (isDisbursed) {
      final loan = postApproval?.loan;
      final bank = postApproval?.bank;
      final offer = postApproval?.offer;

      // 1. Disbursal Amount - only display actual amount, no fake fallback
      final num? rawAmt = loan?.disbursalAmount ?? loan?.approvedAmount ?? offer?.approvedAmount;
      final double? amount = (rawAmt != null && rawAmt > 0) ? rawAmt.toDouble() : null;

      // 2. UTR Reference - ONLY display if real UTR exists (no fake UTR_FTPL... placeholder)
      final String? rawUtr = loan?.disbursalUtr;
      final String? utr = (rawUtr != null && rawUtr.trim().isNotEmpty && rawUtr.trim() != 'N/A')
          ? rawUtr.trim()
          : null;

      // 3. Bank Details from customer profile
      final String? bankName = bank?.bankName;
      final String? accountMasked = bank?.accountMasked;
      final String bankDisplay = (bankName != null && accountMasked != null && accountMasked.isNotEmpty)
          ? '$bankName (..$accountMasked)'
          : (bankName ?? 'your registered bank account');

      // 4. Disbursal Date & Timestamp
      DateTime disbursalDate = now.subtract(const Duration(minutes: 18));
      if (loan?.disbursalCompletedAt != null) {
        final parsed = DateTime.tryParse(loan!.disbursalCompletedAt!);
        if (parsed != null) disbursalDate = parsed;
      } else if (loan?.disbursalDate != null) {
        final parsed = DateTime.tryParse(loan!.disbursalDate!);
        if (parsed != null) disbursalDate = parsed;
      }

      // 5. EMI Amount & Proper Due Date calculation
      final num? rawEmi = offer?.acceptedEmiAmount;
      final double emiAmount = (rawEmi != null && rawEmi > 0)
          ? rawEmi.toDouble()
          : (amount != null ? (amount * 0.52).roundToDouble() : 0.0);

      // Determine proper due date using accepted tenure days (defaulting to 30 days)
      final int tenureDays = (offer?.acceptedTenureDays != null && offer!.acceptedTenureDays! > 0)
          ? offer.acceptedTenureDays!
          : (offer?.allowedTenures.isNotEmpty == true ? offer!.allowedTenures.first : 30);

      DateTime dueDateTime = disbursalDate.add(Duration(days: tenureDays));

      // If calculated due date is in the past, roll forward by tenure period to get current active installment due date
      while (dueDateTime.isBefore(now.subtract(const Duration(days: 1)))) {
        dueDateTime = dueDateTime.add(Duration(days: tenureDays));
      }

      final String formattedDueDate = DateFormat('dd MMM yyyy').format(dueDateTime);
      final String amountStr = amount != null ? CurrencyUtils.formatAmount(amount) : 'Loan';

      seededList = [
        AppNotificationModel(
          id: 'notif_disbursed_${lan.isNotEmpty ? lan : "active"}',
          title: 'Loan Disbursed Successfully! 🎉',
          body: '$amountStr net amount credited to $bankDisplay.',
          category: NotificationCategory.loan,
          timestamp: disbursalDate,
          isRead: false,
          route: lan.isNotEmpty ? '/loan/$lan/loan-details' : '/dashboard',
          actionLabel: 'View RPS Schedule',
          utr: utr,
          amount: amount,
        ),
        if (emiAmount > 0)
          AppNotificationModel(
            id: 'notif_emi_due_${lan.isNotEmpty ? lan : "active"}',
            title: 'EMI Installment Due Soon 📅',
            body: '1st EMI installment of ${CurrencyUtils.formatAmount(emiAmount)} is due on $formattedDueDate.',
            category: NotificationCategory.emi,
            timestamp: now.subtract(const Duration(minutes: 5)),
            isRead: false,
            route: '/repayment',
            actionLabel: 'Pay EMI',
            amount: emiAmount,
          ),
      ];
    } else if (appStatus == 'LENDER_APPROVED' || appStatus == 'PRE_APPROVAL_OFFER_SELECTION') {
      final num? rawAmt = postApproval?.offer.approvedAmount ?? postApproval?.loan.approvedAmount;
      final double? approvedAmt = (rawAmt != null && rawAmt > 0) ? rawAmt.toDouble() : null;
      final String amountStr = approvedAmt != null ? CurrencyUtils.formatAmount(approvedAmt) : 'Pre-approved';

      seededList = [
        AppNotificationModel(
          id: 'notif_approved_${lan.isNotEmpty ? lan : "active"}',
          title: 'Loan Approved! 🎉',
          body: 'Your loan offer of $amountStr has been approved! Complete the final step to receive disbursal.',
          category: NotificationCategory.offer,
          timestamp: now.subtract(const Duration(minutes: 10)),
          isRead: false,
          route: lan.isNotEmpty ? '/loan/$lan/offer' : '/onboarding/offer',
          actionLabel: 'Claim Loan Now',
          amount: approvedAmt,
        ),
      ];
    } else if (appStatus.isNotEmpty && appStatus != 'DRAFT') {
      final lenderName = postApproval?.lender.name ?? customer?.allocatedLenderName ?? 'Fintree Finance';
      seededList = [
        AppNotificationModel(
          id: 'notif_in_progress_${lan.isNotEmpty ? lan : "active"}',
          title: 'Application Under Review ⏳',
          body: 'Your loan application${lan.isNotEmpty ? ' (LAN: $lan)' : ''} is under review by $lenderName.',
          category: NotificationCategory.loan,
          timestamp: now.subtract(const Duration(minutes: 12)),
          isRead: false,
          route: '/application/status',
          actionLabel: 'Check Status',
        ),
      ];
    }

    // Retain existing dynamic notifications in state without duplicates
    final existingIds = seededList.map((n) => n.id).toSet();
    final dynamicItems = state.items.where((n) => !existingIds.contains(n.id)).toList();

    final mergedList = [...dynamicItems, ...seededList];
    mergedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = NotificationsState(
      items: mergedList,
      activeFilter: state.activeFilter,
      isSeeded: true,
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final notifier = NotificationsNotifier();

  // Auto-seed when customer state changes
  ref.listen<JourneyState>(journeyControllerProvider, (previous, next) {
    if (!next.isLoading && next.customer != null) {
      notifier.seedForCustomer(next.customer, next.postApproval);
    }
  });

  // Initial seed check
  final journey = ref.read(journeyControllerProvider);
  if (!journey.isLoading && journey.customer != null) {
    notifier.seedForCustomer(journey.customer, journey.postApproval);
  }

  return notifier;
});
