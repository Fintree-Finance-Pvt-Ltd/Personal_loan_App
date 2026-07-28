import '../constants/app_constants.dart';

class Validators {
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.mobileRegex.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!AppConstants.otpRegex.hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  static String? validatePan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (!AppConstants.panRegex.hasMatch(trimmed)) {
      return 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.pincodeRegex.hasMatch(trimmed)) {
      return 'Enter a valid 6-digit PIN code';
    }
    return null;
  }

  static String? validateIfsc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (!AppConstants.ifscRegex.hasMatch(trimmed)) {
      return 'Enter a valid 11-character IFSC code';
    }
    return null;
  }

  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.bankAccountRegex.hasMatch(trimmed)) {
      return 'Enter a valid account number (9 to 20 digits)';
    }
    return null;
  }

  static String? validateConfirmAccountNumber(String? accountNumber, String? confirmAccountNumber) {
    final err = validateAccountNumber(confirmAccountNumber);
    if (err != null) return err;
    if (accountNumber != confirmAccountNumber) {
      return 'Account numbers do not match';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
