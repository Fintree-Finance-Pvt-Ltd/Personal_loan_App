import 'package:flutter_test/flutter_test.dart';
import 'package:pl_customer_app/core/models/customer_model.dart';

void main() {
  group('CustomerModel Parsing Tests', () {
    test('CustomerModel parses JSON correctly', () {
      final json = {
        'id': '101',
        'customerCode': 'CUST101',
        'mobileNumber': '9876543210',
        'mobileVerified': true,
        'fullName': 'Rahul Sharma',
        'panVerified': true,
        'emailVerified': false,
        'latestApplicationStatus': 'LENDER_APPROVED',
        'latestLan': 'PL260728000123',
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.id, '101');
      expect(customer.customerCode, 'CUST101');
      expect(customer.mobileNumber, '9876543210');
      expect(customer.mobileVerified, isTrue);
      expect(customer.fullName, 'Rahul Sharma');
      expect(customer.panVerified, isTrue);
      expect(customer.latestApplicationStatus, 'LENDER_APPROVED');
      expect(customer.latestLan, 'PL260728000123');
    });
  });
}
