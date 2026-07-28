class AppConstants {
  static const String appName = 'PL Customer App';
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;

  // Regex patterns
  static final RegExp mobileRegex = RegExp(r'^[6-9]\d{9}$');
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
  static final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final RegExp pincodeRegex = RegExp(r'^[1-9][0-9]{5}$');
  static final RegExp ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp bankAccountRegex = RegExp(r'^\d{9,20}$');
  static final RegExp otpRegex = RegExp(r'^\d{6}$');

  // OTP limits
  static const int otpResendCooldownSeconds = 60;
  static const int maxOtpAttempts = 5;
}
