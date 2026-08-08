import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../storage/secure_storage_service.dart';

class CustomerApi {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  CustomerApi(this._apiClient, this._storage);

  Future<Map<String, dynamic>> getCustomerMe() async {
    final res = await _apiClient.get('/customer/me');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getCustomerById(String customerId) async {
    final res = await _apiClient.get('/customer/$customerId');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updateBasicDetails(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    final res = await _apiClient.patch(
      '/customer/$customerId/basic-details',
      data: data,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updateCustomerProfile(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    final res = await _apiClient.patch(
      '/customer/$customerId/profile',
      data: data,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> updatePincode(
    String customerId,
    Map<String, dynamic> body,
  ) async {
    final res = await _apiClient.patch(
      '/customer/$customerId/pincode',
      data: body,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final res = await _apiClient.post(
      '/external-api/reverse-geocode',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> verifyCustomerPan(String panNumber) async {
    final res = await _apiClient.post(
      '/external-api/verify-pan',
      data: {'panNumber': panNumber},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> processPanOcr(dynamic fileOrData) async {
    late final dynamic body;
    late final Map<String, dynamic> headers;

    if (fileOrData is FormData) {
      body = fileOrData;
      headers = {'Content-Type': 'multipart/form-data'};
    } else if (fileOrData is File) {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          fileOrData.path,
          filename: fileOrData.path.split('/').last,
        ),
      });
      body = formData;
      headers = {'Content-Type': 'multipart/form-data'};
    } else {
      body = jsonEncode(fileOrData);
      headers = {'Content-Type': 'application/json'};
    }

    final res = await _apiClient.post(
      '/external-api/pan-ocr',
      data: body,
      options: Options(headers: headers),
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> verifyFaceLiveness(
    String applicationId,
    String inputImage,
  ) async {
    final res = await _apiClient.post(
      '/external-api/face-liveness',
      data: {
        'applicationId': applicationId,
        'inputImage': inputImage,
      },
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateAssessmentPayment(
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/external-api/initiate-payment',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getAssessmentPaymentStatus(
    String paymentId,
    String transactionId,
  ) async {
    final res = await _apiClient.post(
      '/external-api/payment-status',
      data: {
        'paymentId': paymentId,
        'transactionId': transactionId,
        'purpose': 'ASSESSMENT_FEE',
      },
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> saveApplicationAddress(
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.patch(
      '/customer/application/address',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> acceptLenderDecisionConsents() async {
    final consents = [
      {
        'consentType': 'BUREAU_ENQUIRY',
        'consentTemplateId': 'BUREAU_ENQUIRY_V1',
        'consentVersion': '1.0',
        'consentText': 'I authorize a bureau enquiry for this loan application.',
      },
      {
        'consentType': 'LENDER_CREDIT_ASSESSMENT',
        'consentTemplateId': 'LENDER_CREDIT_ASSESSMENT_V1',
        'consentVersion': '1.0',
        'consentText': 'I authorize the allocated lender to assess my eligibility and credit profile.',
      },
      {
        'consentType': 'LENDER_DECISION_REQUEST',
        'consentTemplateId': 'LENDER_DECISION_REQUEST_V1',
        'consentVersion': '1.0',
        'consentText': 'I authorize submission of my completed application to the allocated lender for a lending decision.',
      },
    ];
    final res = await _apiClient.post(
      '/customer/application/decision-consents',
      data: {'consents': consents},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> uploadLivePhotoDocument(FormData formData) async {
    final res = await _apiClient.post(
      '/documents/customer-live-photo',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>?> getCustomerLivePhoto(
    String customerId,
  ) async {
    try {
      final res = await _apiClient.get('/documents/customer/live-photo');
      return _extractData(res);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitCustomerApplication(
    String customerId, {
    Map<String, dynamic> payload = const {},
  }) async {
    final res = await _apiClient.post(
      '/customer/$customerId/submit-application',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> resumeApplication(
    String customerId, {
    Map<String, dynamic> payload = const {},
  }) async {
    final res = await _apiClient.post(
      '/customer/resume-application',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> runEligibility(String customerId) async {
    final res = await _apiClient.post(
      '/customer/$customerId/run-eligibility',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateCustomerAadhaarKyc(
    String customerCode,
  ) async {
    final session = await _getSession();
    final customerId = session?['customerId'] as String?;
    final res = await _apiClient.post(
      '/customer/aadhaar-kyc/digilocker/initiate',
      data: {
        'customerId': customerId,
        'customerCode': customerCode,
        'consentGiven': true,
      },
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getCustomerAadhaarKycStatus() async {
    final session = await _getSession();
    final customerId = session?['customerId'] as String?;
    final query = customerId != null
        ? '?customerId=${Uri.encodeComponent(customerId)}'
        : '';
    final res = await _apiClient.get(
      '/customer/aadhaar-kyc/digilocker/status$query',
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> refreshCustomerAadhaarKycStatus() async {
    final session = await _getSession();
    final customerId = session?['customerId'] as String?;
    final res = await _apiClient.post(
      '/customer/aadhaar-kyc/digilocker/refresh',
      data: {'customerId': customerId},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> saveCurrentAddressSameAsAadhaar() async {
    final res = await _apiClient.post(
      '/customer/aadhaar-kyc/digilocker/current-address/same-as-aadhaar',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateCustomerPayment(
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/external-api/initiate-payment',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getCustomerPaymentStatus(
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/external-api/payment-status',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> retryLenderSubmission(
    String? applicationId,
  ) async {
    final payload = applicationId != null ? {'applicationId': applicationId} : {};
    final res = await _apiClient.post(
      '/customer/application/retry-lender-submission',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getPostApprovalJourney(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/post-approval');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getLoanOffer(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/offer');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getOfferPricing(
    String lan,
    int tenureDays,
  ) async {
    final res = await _apiClient.get(
      '/customer/loans/$lan/offer/pricing?tenureDays=$tenureDays',
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> acceptLoanOffer(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/offer/accept',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateDigilocker(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/digilocker/initiate',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getDigilockerStatus(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/digilocker/status');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> fetchDigilockerDetails(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/digilocker/fetch-details',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> saveAddress(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.patch(
      '/customer/loans/$lan/address',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> verifyBankAccount(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/bank-accounts/verify',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> generateKfs(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/kfs/generate',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getKfs(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/kfs');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> acceptKfs(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/kfs/accept',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateMandate(
    String lan, {
    bool forceNew = false,
    String mandateType = 'ENACH',
  }) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/mandate/initiate',
      data: {'forceNew': forceNew, 'mandateType': mandateType},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getMandateStatus(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/mandate/status');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> refreshMandateStatus(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/mandate/refresh-status',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateEsign(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/electronic-sign/prepare',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getEsignStatus(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/electronic-sign/status');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> prepareElectronicSign(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/electronic-sign/prepare',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> markDocumentViewed(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/electronic-sign/document/viewed',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> sendSigningOtp(
    String lan,
    bool consentAccepted,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/electronic-sign/otp/send',
      data: {'consentAccepted': consentAccepted},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> verifySigningOtp(
    String lan,
    String otpSessionId,
    String otp,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/electronic-sign/otp/verify',
      data: {'otpSessionId': otpSessionId, 'otp': otp},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getElectronicSignStatus(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/electronic-sign/status');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> requestDisbursal(String lan) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/disbursal/request',
      data: const {},
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getDisbursalStatus(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/disbursal/status');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> getCustomerLoanDetails(String lan) async {
    final res = await _apiClient.get('/customer/loans/$lan/details');
    return _extractData(res);
  }

  Future<Map<String, dynamic>> initiateRepaymentPayment(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/repay/initiate',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>> confirmRepayment(
    String lan,
    Map<String, dynamic> payload,
  ) async {
    final res = await _apiClient.post(
      '/customer/loans/$lan/repay/confirm',
      data: payload,
    );
    return _extractData(res);
  }

  Future<Map<String, dynamic>?> _getSession() async {
    try {
      final customerId = await _storage.getCustomerId();
      final mobileNumber = await _storage.getMobileNumber();
      if (customerId != null && mobileNumber != null) {
        return {'customerId': customerId, 'mobileNumber': mobileNumber};
      }
    } catch (_) {}
    return null;
  }

  dynamic _extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response['data'] ?? response;
    }
    return response;
  }
}
