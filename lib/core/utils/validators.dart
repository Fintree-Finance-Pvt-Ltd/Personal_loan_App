import '../constants/app_constants.dart';
import '../localization/app_localizations.dart';

class Validators {
  static String? validateMobile(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_mobile') ?? 'Please enter your mobile number';
    }
    final trimmed = value.trim();
    if (trimmed.length != 10) {
      return loc?.tr('invalid_mobile') ?? 'Mobile number must be exactly 10 digits';
    }
    if (!trimmed.startsWith(RegExp(r'[6-9]'))) {
      return loc?.tr('invalid_mobile') ?? 'Mobile number must start with 6, 7, 8, or 9';
    }
    if (!AppConstants.mobileRegex.hasMatch(trimmed)) {
      return loc?.tr('invalid_mobile') ?? 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateOtp(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_otp') ?? 'OTP is required';
    }
    if (!AppConstants.otpRegex.hasMatch(value.trim())) {
      return loc?.tr('invalid_otp') ?? 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  static String? validatePan(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_pan') ?? 'PAN number is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (!AppConstants.panRegex.hasMatch(trimmed)) {
      return loc?.tr('invalid_pan') ?? 'Enter a valid 10-character PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  static String? validateEmail(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePincode(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_pincode') ?? 'PIN code is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.pincodeRegex.hasMatch(trimmed)) {
      return loc?.tr('invalid_pincode') ?? 'Enter a valid 6-digit PIN code';
    }
    return null;
  }

  static String? validateIfsc(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_ifsc') ?? 'IFSC code is required';
    }
    final trimmed = value.trim().toUpperCase();
    if (!AppConstants.ifscRegex.hasMatch(trimmed)) {
      return loc?.tr('invalid_ifsc') ?? 'Enter a valid 11-character IFSC code';
    }
    return null;
  }

  static String? validateAccountNumber(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('invalid_account') ?? 'Account number is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.bankAccountRegex.hasMatch(trimmed)) {
      return loc?.tr('invalid_account') ?? 'Enter a valid account number (9 to 20 digits)';
    }
    return null;
  }

  static String? validateConfirmAccountNumber(String? accountNumber, String? confirmAccountNumber, [AppLocalizations? loc]) {
    final err = validateAccountNumber(confirmAccountNumber, loc);
    if (err != null) return err;
    if (accountNumber != confirmAccountNumber) {
      return loc?.tr('acc_mismatch') ?? 'Account numbers do not match';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.tr('req_field', {'field': fieldName}) ?? '$fieldName is required';
    }
    return null;
  }
}
