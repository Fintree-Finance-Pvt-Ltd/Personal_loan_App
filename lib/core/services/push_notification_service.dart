import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../storage/secure_storage_service.dart';

/// Background FCM message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('Handling background FCM message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Function(String route)? _navigationCallback;

  // Channel IDs
  static const String dropoffChannelId = 'dropoff_recovery_channel';
  static const String dropoffChannelName = 'Drop-off Recovery Reminders';
  static const String emiChannelId = 'emi_reminders_channel';
  static const String emiChannelName = 'EMI Due Date Reminders';

  // Action IDs
  static const String payNowActionId = 'PAY_NOW_ACTION';

  /// Initialize Firebase FCM & Local Notifications setup
  Future<void> initialize({Function(String route)? onNavigate}) async {
    _navigationCallback = onNavigate;

    // 1. Initialize Timezones for scheduled reminders
    tz.initializeTimeZones();

    // 2. Register Background FCM Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Request Notification Permissions
    await requestPermissions();

    // 4. Setup Flutter Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'EMI_REMINDER_CATEGORY',
          actions: [
            DarwinNotificationAction.plain(
              payNowActionId,
              'Pay Now',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 5. Setup Android Notification Channels
    await _createNotificationChannels();

    // 6. Listen for Foreground FCM Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message received: ${message.notification?.title}');
      _showLocalNotificationFromFcm(message);
    });

    // 7. Listen for Background FCM message tap app launches
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via FCM notification: ${message.data}');
      _handlePayloadData(message.data);
    });

    // 8. Handle initial notification launch (app was closed)
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handlePayloadData(initialMessage.data);
    }
  }

  /// Request User Notification Permissions
  Future<bool> requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
    debugPrint('Push Notification Authorization Status: ${settings.authorizationStatus}');
    return granted;
  }

  /// Get current Device FCM Token
  Future<String?> getFcmToken() async {
    try {
      final token = await _fcm.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error fetching FCM Token: $e');
      return null;
    }
  }

  /// Listen to FCM Token refresh
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  /// Create Android Notification Channels with Action Buttons
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel dropoffChannel = AndroidNotificationChannel(
        dropoffChannelId,
        dropoffChannelName,
        description: 'Notifications sent when a user abandons loan onboarding or KYC',
        importance: Importance.high,
      );

      const AndroidNotificationChannel emiChannel = AndroidNotificationChannel(
        emiChannelId,
        emiChannelName,
        description: 'Notifications sent for EMI due date reminders with Pay Now actions',
        importance: Importance.max,
        playSound: true,
      );

      await androidPlugin.createNotificationChannel(dropoffChannel);
      await androidPlugin.createNotificationChannel(emiChannel);
    }
  }

  /// Show Local Notification when FCM message arrives in foreground
  Future<void> _showLocalNotificationFromFcm(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final String route = message.data['route'] ?? '/dashboard';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      emiChannelId,
      emiChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          payNowActionId,
          'Pay Now',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'EMI_REMINDER_CATEGORY',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: jsonEncode({'route': route}),
    );
  }

  // ==========================================
  // FEATURE 1: Drop-off Recovery Notifications
  // ==========================================

  /// Schedule a Drop-off Recovery push notification after 2 hours
  /// If customer abandons at Aadhaar KYC or KFS
  Future<void> scheduleDropoffRecovery({
    required String lan,
    required String step, // 'digilocker' or 'kfs'
    Duration delay = const Duration(hours: 2),
  }) async {
    final int id = step == 'digilocker' ? 1001 : 1002;
    final String route = step == 'digilocker' 
        ? (lan.isNotEmpty ? '/loan/$lan/digilocker' : '/onboarding/digilocker')
        : '/loan/$lan/kfs';

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dropoffChannelId,
      dropoffChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      'Your ₹25,000 loan offer is waiting! 🚀',
      'Complete 1 final step to receive instant disbursal.',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'route': route, 'type': 'dropoff_recovery'}),
    );

    debugPrint('Scheduled Drop-off Recovery notification ($step) for: $scheduledDate');
  }

  /// Cancel Drop-off Recovery notification when step is completed
  Future<void> cancelDropoffRecovery(String step) async {
    final int id = step == 'digilocker' ? 1001 : 1002;
    await _localNotifications.cancel(id);
    debugPrint('Cancelled Drop-off Recovery notification for step: $step');
  }

  // ==========================================
  // FEATURE 3: Instant Loan Approval Notification
  // ==========================================

  /// Send instant in-app / local push notification when loan/credit is approved
  Future<void> sendLoanApprovedNotification({
    required String lan,
    double? loanAmount,
  }) async {
    final storage = SecureStorageService();
    final bool alreadyNotified = await storage.isLoanApprovedNotified(lan);
    if (alreadyNotified) {
      debugPrint('Loan Approval notification already shown for LAN: $lan. Skipping duplicate notification.');
      return;
    }

    const int notificationId = 999;
    final String amountStr = loanAmount != null && loanAmount > 0 
        ? '₹${loanAmount.toStringAsFixed(0)}'
        : 'your approved amount';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dropoffChannelId,
      dropoffChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        'Congratulations! Your loan of $amountStr has been APPROVED! 🎉 Complete bank verification & e-Sign to get instant disbursal.',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final route = lan.isNotEmpty ? '/loan/$lan/offer' : '/onboarding/offer';

    await _localNotifications.show(
      notificationId,
      'Congratulations! Loan Approved! 🎉',
      'Your loan of $amountStr is approved! Complete 1 step to get money in your account.',
      platformDetails,
      payload: jsonEncode({'route': route, 'type': 'loan_approved'}),
    );

    await storage.markLoanApprovedNotified(lan);
    debugPrint('Instant Loan Approval notification sent and recorded for LAN: $lan');
  }

  // ==========================================
  // FEATURE 4: Universal 2-Hour Stage Drop-off Recovery
  // ==========================================

  /// Schedules a stage-tailored drop-off recovery notification set for 2 hours in the future
  /// for ANY stage in the customer journey. Cancels any existing pending stage drop-off timer (ID 1000).
  Future<void> scheduleStageDropoffRecovery({
    required String targetRoute,
    String? lan,
    double? amount,
  }) async {
    const int stageNotificationId = 1000;
    
    // Always cancel existing pending stage timer first
    await _localNotifications.cancel(stageNotificationId);

    // Don't schedule if customer reached dashboard or login or splash
    if (targetRoute == '/dashboard' || targetRoute == '/login' || targetRoute == '/splash') {
      return;
    }

    final String offerAmountStr = amount != null && amount > 0 
        ? '₹${amount.toStringAsFixed(0)}' 
        : '₹25,000';

    String title = 'Your $offerAmountStr loan offer is waiting! 🚀';
    String body = 'Complete your next step to receive instant disbursal.';

    if (targetRoute.contains('/pan')) {
      title = 'Verify PAN & Unlock Loan Offer! 💳';
      body = 'Complete your quick PAN check to reveal your instant loan offer of up to ₹500,000.';
    } else if (targetRoute.contains('/basic-details') || targetRoute.contains('/profile')) {
      title = 'Complete Profile & Get Disbursal! 📝';
      body = 'Your $offerAmountStr loan process is 80% complete. Finish details now!';
    } else if (targetRoute.contains('/processing-fee')) {
      title = 'Processing Fee Pending! ⚡';
      body = 'Pay processing fee to initiate instant credit check and loan approval.';
    } else if (targetRoute.contains('/live-photo')) {
      title = 'Quick Selfie Verification Required! 📸';
      body = 'Take a 5-second selfie to complete identity check and unlock instant loan.';
    } else if (targetRoute.contains('/digilocker')) {
      title = 'Aadhaar KYC Pending! 🔒';
      body = 'Your $offerAmountStr loan offer is waiting! Complete 1-click Aadhaar KYC now.';
    } else if (targetRoute.contains('/address')) {
      title = 'Confirm Address for Instant Disbursal! 🏠';
      body = 'Confirm your current address to move your loan application to final approval.';
    } else if (targetRoute.contains('/account-aggregator') || targetRoute.contains('/bank')) {
      title = 'Bank Account Verification Pending! 🏦';
      body = 'Link your bank account to receive $offerAmountStr directly in your bank account.';
    } else if (targetRoute.contains('/kfs')) {
      title = 'Accept KFS & Get Instant Cash! 📑';
      body = 'Your Key Fact Statement (KFS) is ready! Accept terms to proceed to e-Sign.';
    } else if (targetRoute.contains('/mandate')) {
      title = 'Setup Auto-Debit Mandate! 💳';
      body = 'Set up e-Mandate for hassle-free repayment and instant disbursal authorization.';
    } else if (targetRoute.contains('/esign')) {
      title = 'Final Step: e-Sign Loan Agreement! ✍️';
      body = 'Sign your loan agreement now to trigger instant bank transfer in 5 minutes!';
    } else if (targetRoute.contains('/offer')) {
      title = 'Your $offerAmountStr Approved Offer is Ready! 🎉';
      body = 'Select your tenure and accept your approved loan amount before it expires.';
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dropoffChannelId,
      dropoffChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      stageNotificationId,
      title,
      body,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'route': targetRoute, 'type': 'stage_dropoff_recovery'}),
    );

    debugPrint('Scheduled Universal Stage Drop-off Recovery for "$targetRoute" at: $scheduledDate');
  }

  // ==========================================
  // FEATURE 2: EMI Due Date Reminders
  // ==========================================

  /// Schedule EMI Reminders (3 days before, 1 day before, and on the due date)
  /// Includes direct "Pay Now" deep-link action button
  Future<void> scheduleEmiReminders({
    required String lan,
    required double amount,
    required DateTime dueDate,
  }) async {
    final String route = '/loan/$lan/repay';
    final formattedAmount = '₹${amount.toStringAsFixed(0)}';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      emiChannelId,
      emiChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          payNowActionId,
          'Pay Now',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      categoryIdentifier: 'EMI_REMINDER_CATEGORY',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 1. Reminder: 3 Days Before Due Date
    final threeDaysBefore = dueDate.subtract(const Duration(days: 3));
    if (threeDaysBefore.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        2001,
        'EMI Reminder: 3 Days Left ⏳',
        'Your EMI payment of $formattedAmount is due in 3 days. Tap to pay now and avoid late charges.',
        tz.TZDateTime.from(threeDaysBefore, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'route': route, 'action': 'PAY_NOW'}),
      );
    }

    // 2. Reminder: 1 Day Before Due Date
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        2002,
        'Urgent EMI Reminder: Due Tomorrow 🔔',
        'Your EMI payment of $formattedAmount is due tomorrow. Pay now with 1 click.',
        tz.TZDateTime.from(oneDayBefore, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'route': route, 'action': 'PAY_NOW'}),
      );
    }

    // 3. Reminder: On Due Date
    if (dueDate.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        2003,
        'EMI Payment Due Today! ⚠️',
        'Today is your EMI due date! Pay $formattedAmount now to keep your credit score safe.',
        tz.TZDateTime.from(dueDate, tz.local),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'route': route, 'action': 'PAY_NOW'}),
      );
    }

    debugPrint('Scheduled EMI due date reminders for LAN $lan on $dueDate');
  }

  /// Cancel all scheduled EMI reminders when loan is paid off
  Future<void> cancelEmiReminders() async {
    await _localNotifications.cancel(2001);
    await _localNotifications.cancel(2002);
    await _localNotifications.cancel(2003);
    debugPrint('Cancelled all EMI reminders.');
  }

  // ==========================================
  // Helper Payload Navigation Handlers
  // ==========================================

  void _handleNotificationTap(String? rawPayload) {
    if (rawPayload == null || rawPayload.isEmpty) return;
    try {
      final Map<String, dynamic> data = jsonDecode(rawPayload);
      _handlePayloadData(data);
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  void _handlePayloadData(Map<String, dynamic> data) {
    final String? route = data['route'];
    if (route != null && route.isNotEmpty) {
      debugPrint('Navigating via deep link route: $route');
      _navigationCallback?.call(route);
    }
  }

  // ==========================================
  // FEATURE 5: Automated Instant Notifications
  // ==========================================

  /// Send instant push notification when user logs in successfully
  Future<void> sendLoginSuccessNotification({String? userName}) async {
    const int notificationId = 901;
    final String greeting = (userName != null && userName.trim().isNotEmpty)
        ? 'Welcome back, ${userName.trim()}! 👋'
        : 'Welcome back to Finle! 👋';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dropoffChannelId,
      dropoffChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        'You have successfully logged into your account. Explore instant loan offers and updates now.',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      greeting,
      'You have successfully logged into your account.',
      platformDetails,
      payload: jsonEncode({'route': '/dashboard', 'type': 'login_success'}),
    );

    debugPrint('Instant Login Success notification sent.');
  }

  /// Send instant notification when DigiLocker / Aadhaar KYC is verified
  Future<void> sendKycSuccessNotification() async {
    const int notificationId = 902;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dropoffChannelId,
      dropoffChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        'Your Aadhaar KYC verification is complete! Proceed to the next step to claim your loan.',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      'Aadhaar KYC Verified! ✅',
      'Your identity verification was successful.',
      platformDetails,
      payload: jsonEncode({'route': '/dashboard', 'type': 'kyc_success'}),
    );

    debugPrint('Instant KYC Success notification sent.');
  }

  /// Send instant notification when loan EMI repayment succeeds
  Future<void> sendRepaymentSuccessNotification({
    required double amount,
    String? lan,
  }) async {
    const int notificationId = 903;
    final String amountStr = '₹${amount.toStringAsFixed(0)}';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      emiChannelId,
      emiChannelName,
      icon: '@mipmap/launcher_icon',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        'Thank you! Your loan EMI payment of $amountStr was completed successfully.',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final route = (lan != null && lan.isNotEmpty) ? '/loan/$lan/repay' : '/dashboard';

    await _localNotifications.show(
      notificationId,
      'EMI Repayment Successful! 💳',
      'Payment of $amountStr received. Thank you!',
      platformDetails,
      payload: jsonEncode({'route': route, 'type': 'repayment_success'}),
    );

    debugPrint('Instant Repayment Success notification sent for amount: $amountStr');
  }
}
