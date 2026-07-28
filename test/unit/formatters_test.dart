import 'package:flutter_test/flutter_test.dart';
import 'package:pl_customer_app/core/utils/formatters.dart';

void main() {
  group('Formatters & Masking Tests', () {
    test('maskPan masks first 5 characters', () {
      expect(Formatters.maskPan('ABCDE1234F'), 'XXXXX1234F');
    });

    test('maskAadhaar masks all except last 4 digits', () {
      expect(Formatters.maskAadhaar('123456789012'), 'XXXX-XXXX-9012');
    });

    test('maskBankAccount masks prefix', () {
      expect(Formatters.maskBankAccount('1234567890'), 'XXXXXX7890');
    });

    test('maskMobile masks middle 6 digits', () {
      expect(Formatters.maskMobile('9876543210'), '98XXXXXX10');
    });
  });
}
