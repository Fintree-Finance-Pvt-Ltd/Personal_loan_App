import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyCustomerId = 'customer_id';
  static const String _keyMobileNumber = 'mobile_number';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyActiveLan = 'active_lan';

  Future<void> saveSession({
    required String customerId,
    required String mobileNumber,
    String? token,
  }) async {
    await _storage.write(key: _keyCustomerId, value: customerId);
    await _storage.write(key: _keyMobileNumber, value: mobileNumber);
    if (token != null) {
      await _storage.write(key: _keyAuthToken, value: token);
    }
  }

  Future<String?> getCustomerId() async => await _storage.read(key: _keyCustomerId);
  Future<String?> getMobileNumber() async => await _storage.read(key: _keyMobileNumber);
  Future<String?> getAuthToken() async => await _storage.read(key: _keyAuthToken);

  Future<void> saveActiveLan(String lan) async {
    await _storage.write(key: _keyActiveLan, value: lan);
  }

  Future<String?> getActiveLan() async => await _storage.read(key: _keyActiveLan);

  Future<bool> isLoanApprovedNotified(String lan) async {
    final key = 'loan_approved_notified_${lan.isEmpty ? 'default' : lan}';
    final val = await _storage.read(key: key);
    return val == 'true';
  }

  Future<void> markLoanApprovedNotified(String lan) async {
    final key = 'loan_approved_notified_${lan.isEmpty ? 'default' : lan}';
    await _storage.write(key: key, value: 'true');
  }

  Future<String> getSelectedLanguage() async {
    return await _storage.read(key: 'app_language') ?? 'en';
  }

  Future<void> setSelectedLanguage(String lang) async {
    await _storage.write(key: 'app_language', value: lang);
  }

  static const String _keyNotifications = 'user_notifications_payload';

  Future<void> saveStoredNotifications(String rawJson) async {
    await _storage.write(key: _keyNotifications, value: rawJson);
  }

  Future<String?> getStoredNotifications() async {
    return await _storage.read(key: _keyNotifications);
  }

  Future<bool> isLoanDisbursedNotified(String lan) async {
    final key = 'loan_disbursed_notified_${lan.isEmpty ? 'default' : lan}';
    final val = await _storage.read(key: key);
    return val == 'true';
  }

  Future<void> markLoanDisbursedNotified(String lan) async {
    final key = 'loan_disbursed_notified_${lan.isEmpty ? 'default' : lan}';
    await _storage.write(key: key, value: 'true');
  }

  static const String _keyDismissedNotifs = 'dismissed_notification_ids';

  Future<Set<String>> getDismissedNotificationIds() async {
    final val = await _storage.read(key: _keyDismissedNotifs);
    if (val == null || val.isEmpty) return {};
    try {
      final decoded = jsonDecode(val);
      if (decoded is List) return decoded.map((e) => e.toString()).toSet();
    } catch (_) {}
    return {};
  }

  Future<void> addDismissedNotificationId(String id) async {
    final set = await getDismissedNotificationIds();
    set.add(id);
    await _storage.write(key: _keyDismissedNotifs, value: jsonEncode(set.toList()));
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
