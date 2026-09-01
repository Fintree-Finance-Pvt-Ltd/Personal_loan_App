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

    test('CustomerModel parses AA status correctly', () {
      final json1 = {
        'id': '13',
        'customerCode': 'CUST13',
        'mobileNumber': '9876543210',
        'mobileVerified': true,
        'panVerified': true,
        'emailVerified': true,
        'aaVerified': true,
        'aaStatus': 'SUCCESS',
      };

      final customer1 = CustomerModel.fromJson(json1);
      expect(customer1.aaVerified, isTrue);
      expect(customer1.aaStatus, 'SUCCESS');

      final json2 = {
        'id': '13',
        'customerCode': 'CUST13',
        'mobileNumber': '9876543210',
        'mobileVerified': true,
        'panVerified': true,
        'emailVerified': true,
        'journey': {
          'accountAggregatorStatus': 'SUCCESS',
          'updateReadiness': {'reasons': []}
        }
      };

      final customer2 = CustomerModel.fromJson(json2);
      expect(customer2.aaVerified, isTrue);
    });

    test('CustomerModel parses PRE_APPROVAL_OFFER_SELECTION step correctly', () {
      final json = {
        'id': '102',
        'customerCode': 'CUST102',
        'mobileNumber': '9876543210',
        'mobileVerified': true,
        'panVerified': true,
        'latestApplicationStatus': 'LENDER_PRE_APPROVED',
        'journey': {
          'nextPermittedStep': 'PRE_APPROVAL_OFFER_SELECTION',
          'platformLan': 'LAN123456'
        }
      };

      final customer = CustomerModel.fromJson(json);
      expect(customer.latestApplicationStatus, 'LENDER_PRE_APPROVED');
      expect(customer.nextPermittedStep, 'PRE_APPROVAL_OFFER_SELECTION');
      expect(customer.platformLan, 'LAN123456');
    });
  });
}
