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

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
