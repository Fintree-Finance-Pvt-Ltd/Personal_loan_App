class ApiEndpoints {
  // Auth & OTP
  static const String sendMobileOtp = '/otp/mobile/send';
  static const String verifyMobileOtp = '/otp/mobile/verify';
  static const String sendEmailOtp = '/otp/email/send';
  static const String verifyEmailOtp = '/otp/email/verify';

  // Customer Profile
  static String customerDetails(String id) => '/customer/$id';
  static String updateBasicDetails(String id) => '/customer/$id/basic-details';
  static String updatePincode(String id) => '/customer/$id/pincode';
  static String updateProfile(String id) => '/customer/$id/profile';
  static String submitApplication(String id) => '/customer/$id/submit-application';

  // External Verification APIs
  static const String verifyPan = '/external-api/verify-pan';
  static const String checkFaceLiveness = '/external-api/face-liveness';
  static const String uploadCustomerLivePhoto = '/documents/customer-live-photo';
  static String getCustomerLivePhoto(String customerId) => '/documents/customer/$customerId/live-photo';
  static const String initiatePayment = '/external-api/initiate-payment';
  static const String getPaymentStatus = '/external-api/payment-status';

  // Post Approval Loan Journey
  static String postApprovalJourney(String lan) => '/customer/loans/$lan/post-approval';
  static String getLoanOffer(String lan) => '/customer/loans/$lan/offer';
  static String acceptLoanOffer(String lan) => '/customer/loans/$lan/offer/accept';
  static String initiateDigilocker(String lan) => '/customer/loans/$lan/digilocker/initiate';
  static String digilockerStatus(String lan) => '/customer/loans/$lan/digilocker/status';
  static String fetchDigilockerDetails(String lan) => '/customer/loans/$lan/digilocker/fetch-details';
  static String saveAddress(String lan) => '/customer/loans/$lan/address';
  static String verifyBankAccount(String lan) => '/customer/loans/$lan/bank-accounts/verify';
  static String generateKfs(String lan) => '/customer/loans/$lan/kfs/generate';
  static String getKfs(String lan) => '/customer/loans/$lan/kfs';
  static String acceptKfs(String lan) => '/customer/loans/$lan/kfs/accept';
  static String initiateMandate(String lan) => '/customer/loans/$lan/mandate/initiate';
  static String mandateStatus(String lan) => '/customer/loans/$lan/mandate/status';
  static String initiateEsign(String lan) => '/customer/loans/$lan/esign/initiate';
  static String esignStatus(String lan) => '/customer/loans/$lan/esign/status';
  static String requestDisbursal(String lan) => '/customer/loans/$lan/disbursal/request';
  static String disbursalStatus(String lan) => '/customer/loans/$lan/disbursal/status';
}
