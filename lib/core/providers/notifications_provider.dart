import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/app_notification_model.dart';
import '../utils/currency_utils.dart';
import '../../features/dashboard/presentation/journey_controller.dart';
import '../models/customer_model.dart';
import '../models/post_approval_model.dart';

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
  NotificationsNotifier() : super(const NotificationsState());

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
    final lan = customer?.latestLan ?? customer?.platformLan ?? 'FTPL00000011';
    final appStatus = customer?.latestApplicationStatus?.toUpperCase() ?? '';
    final isDisbursed = appStatus == 'DISBURSED' ||
        customer?.latestLoanStatus == 'DISBURSED' ||
        postApproval?.workflow.currentStep == 'DISBURSED' ||
        postApproval?.loan.disbursalCompletedAt != null;

    final now = DateTime.now();

    List<AppNotificationModel> initialList = [];

    if (isDisbursed) {
      final loan = postApproval?.loan;
      final bank = postApproval?.bank;
      final offer = postApproval?.offer;

      // 1. Dynamic Disbursal Amount
      final num? rawAmt = loan?.disbursalAmount ?? loan?.approvedAmount ?? offer?.approvedAmount;
      final double amount = (rawAmt != null && rawAmt > 0) ? rawAmt.toDouble() : 5000.0;

      // 2. Dynamic UTR Reference from backend post-approval loan model
      final String rawUtr = loan?.disbursalUtr ?? '';
      final String utr = (rawUtr.isNotEmpty && rawUtr != 'N/A') ? rawUtr : 'UTR_$lan';

      // 3. Dynamic Bank Details from customer profile
      final String bankName = bank?.bankName ?? 'Bank Account';
      final String accountMasked = bank?.accountMasked ?? '';
      final String bankDisplay = accountMasked.isNotEmpty ? '$bankName (..$accountMasked)' : bankName;

      // 4. Dynamic EMI Amount & Due Date
      final num? rawEmi = offer?.acceptedEmiAmount;
      final double emiAmount = (rawEmi != null && rawEmi > 0)
          ? rawEmi.toDouble()
          : (amount > 0 ? (amount * 0.52).roundToDouble() : 2600.0);

      DateTime dueDateTime = now.add(const Duration(days: 30));
      if (loan?.disbursalCompletedAt != null) {
        final parsed = DateTime.tryParse(loan!.disbursalCompletedAt!);
        if (parsed != null) dueDateTime = parsed.add(const Duration(days: 30));
      }
      final String formattedDueDate = DateFormat('dd MMM yyyy').format(dueDateTime);

      initialList = [
        AppNotificationModel(
          id: 'notif_disbursed_$lan',
          title: 'Loan Disbursed Successfully! 🎉',
          body: '${CurrencyUtils.formatAmount(amount)} net amount credited to $bankDisplay.',
          category: NotificationCategory.loan,
          timestamp: now.subtract(const Duration(minutes: 18)),
          isRead: false,
          route: '/loan/$lan/loan-details',
          actionLabel: 'View RPS Schedule',
          utr: utr,
          amount: amount,
        ),
        AppNotificationModel(
          id: 'notif_emi_due_$lan',
          title: 'EMI Installment Due Soon 📅',
          body: '1st EMI installment of ${CurrencyUtils.formatAmount(emiAmount)} is due on $formattedDueDate.',
          category: NotificationCategory.emi,
          timestamp: now.subtract(const Duration(hours: 3)),
          isRead: false,
          route: '/repayment',
          actionLabel: 'Pay EMI',
          amount: emiAmount,
        ),
      ];
    } else if (appStatus.isNotEmpty) {
      final lenderName = postApproval?.lender.name ?? 'Fintree Finance';
      initialList = [
        AppNotificationModel(
          id: 'notif_in_progress_$lan',
          title: 'Application Underwriting ⏳',
          body: 'Your loan application (LAN: $lan) is currently under review by $lenderName.',
          category: NotificationCategory.loan,
          timestamp: now.subtract(const Duration(minutes: 12)),
          isRead: false,
          route: '/application/status',
          actionLabel: 'Check Status',
        ),
      ];
    } else {
      initialList = [];
    }

    state = NotificationsState(
      items: initialList,
      activeFilter: NotificationCategory.all,
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
