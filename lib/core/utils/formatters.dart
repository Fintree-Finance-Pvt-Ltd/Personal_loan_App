class Formatters {
  /// Masks PAN: ABCDE1234F -> XXXXX1234F
  static String maskPan(String? pan) {
    if (pan == null || pan.length < 10) return 'XXXXX0000X';
    return 'XXXXX${pan.substring(5)}';
  }

  /// Masks Aadhaar: 1234 5678 9012 -> XXXX-XXXX-9012
  static String maskAadhaar(String? aadhaar) {
    if (aadhaar == null || aadhaar.length < 4) return 'XXXX-XXXX-XXXX';
    final clean = aadhaar.replaceAll(RegExp(r'\s|-'), '');
    if (clean.length < 4) return 'XXXX-XXXX-XXXX';
    final last4 = clean.substring(clean.length - 4);
    return 'XXXX-XXXX-$last4';
  }

  /// Masks Bank Account Number: 1234567890 -> XXXXXX7890
  static String maskBankAccount(String? account) {
    if (account == null || account.length < 4) return 'XXXXXXXX0000';
    final last4 = account.substring(account.length - 4);
    final maskedPrefix = 'X' * (account.length - 4);
    return '$maskedPrefix$last4';
  }

  /// Masks Mobile Number: 9876543210 -> 98XXXXXX10
  static String maskMobile(String? mobile) {
    if (mobile == null || mobile.length < 10) return 'XXXXXXXXXX';
    final clean = mobile.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) return 'XXXXXXXXXX';
    return '${clean.substring(0, 2)}XXXXXX${clean.substring(8)}';
  }
}
