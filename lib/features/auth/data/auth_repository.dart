import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/customer_model.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<Map<String, dynamic>> sendMobileOtp({
    required String mobileNumber,
    required bool consentGiven,
    String? consentText,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendMobileOtp,
      data: {
        'mobileNumber': mobileNumber,
        'consentGiven': consentGiven,
        'consentText': consentText ?? 'I consent to receiving OTP and terms for Personal Loan.',
      },
    );
    return response;
  }

  Future<CustomerModel> verifyMobileOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyMobileOtp,
      data: {
        'mobileNumber': mobileNumber,
        'otp': otp,
      },
    );

    // Deep extraction for nested backend response structure
    dynamic rawData = response;
    if (rawData is Map<String, dynamic> && rawData['data'] != null) {
      rawData = rawData['data'];
    }
    if (rawData is Map<String, dynamic> && rawData['data'] != null) {
      rawData = rawData['data'];
    }
    
    Map<String, dynamic> rawCustomer = {};
    if (rawData is Map<String, dynamic> && rawData['customer'] != null) {
      rawCustomer = Map<String, dynamic>.from(rawData['customer']);
    } else if (rawData is Map<String, dynamic>) {
      rawCustomer = Map<String, dynamic>.from(rawData);
    }

    final accessToken = rawData is Map<String, dynamic> ? rawData['accessToken'] as String? : null;

    final customer = CustomerModel.fromJson(rawCustomer);

    if (customer.id.isNotEmpty) {
      await _storageService.saveSession(
        customerId: customer.id,
        mobileNumber: customer.mobileNumber.isNotEmpty ? customer.mobileNumber : mobileNumber,
        token: accessToken,
      );
    }

    return customer;
  }

  Future<void> logout() async {
    await _storageService.clearSession();
  }
}
