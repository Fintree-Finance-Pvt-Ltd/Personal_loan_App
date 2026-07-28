import 'package:flutter_test/flutter_test.dart';
import 'package:pl_customer_app/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('validateMobile returns null for valid 10-digit mobile', () {
      expect(Validators.validateMobile('9876543210'), isNull);
      expect(Validators.validateMobile('8123456789'), isNull);
    });

    test('validateMobile returns error string for invalid mobile', () {
      expect(Validators.validateMobile('12345'), isNotNull);
      expect(Validators.validateMobile('5876543210'), isNotNull);
      expect(Validators.validateMobile(''), isNotNull);
    });

    test('validatePan returns null for valid PAN', () {
      expect(Validators.validatePan('ABCDE1234F'), isNull);
    });

    test('validatePan returns error string for invalid PAN', () {
      expect(Validators.validatePan('ABCD1234F'), isNotNull);
      expect(Validators.validatePan('12345ABCDE'), isNotNull);
    });

    test('validatePincode returns null for valid 6-digit PIN', () {
      expect(Validators.validatePincode('110001'), isNull);
    });

    test('validateIfsc returns null for valid IFSC', () {
      expect(Validators.validateIfsc('HDFC0001234'), isNull);
    });

    test('validateAccountNumber matches confirm account number', () {
      expect(Validators.validateConfirmAccountNumber('1234567890', '1234567890'), isNull);
      expect(Validators.validateConfirmAccountNumber('1234567890', '9876543210'), isNotNull);
    });
  });
}
