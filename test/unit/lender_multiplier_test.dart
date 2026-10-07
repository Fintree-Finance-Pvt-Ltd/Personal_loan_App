import 'package:flutter_test/flutter_test.dart';
import 'package:pl_customer_app/core/models/lender_offer_multiplier.dart';

void main() {
  group('LenderOfferMultiplier & LenderMultiplierCalculator Tests', () {
    test('Correctly resolves multiplier for 0 completed loans', () {
      final multiplier = LenderMultiplierCalculator.getMultiplier(0);
      expect(multiplier, 1.0000);
    });

    test('Correctly resolves multiplier for 1 completed loan', () {
      final multiplier = LenderMultiplierCalculator.getMultiplier(1);
      expect(multiplier, 1.2500);
    });

    test('Correctly resolves multiplier for 2 completed loans', () {
      final multiplier = LenderMultiplierCalculator.getMultiplier(2);
      expect(multiplier, 1.7500);
    });

    test('Correctly resolves multiplier for 3+ completed loans', () {
      final multiplier3 = LenderMultiplierCalculator.getMultiplier(3);
      final multiplier5 = LenderMultiplierCalculator.getMultiplier(5);
      expect(multiplier3, 1.8500);
      expect(multiplier5, 1.8500);
    });

    test('Calculates revised loan limit accurately based on multiplier', () {
      const baseAmount = 50000;
      final limit0 = LenderMultiplierCalculator.calculateRevisedLimit(baseAmount, 0);
      final limit1 = LenderMultiplierCalculator.calculateRevisedLimit(baseAmount, 1);
      final limit2 = LenderMultiplierCalculator.calculateRevisedLimit(baseAmount, 2);
      final limit3 = LenderMultiplierCalculator.calculateRevisedLimit(baseAmount, 3);

      expect(limit0, 50000.0);
      expect(limit1, 62500.0); // 50,000 * 1.25
      expect(limit2, 87500.0); // 50,000 * 1.75
      expect(limit3, 92500.0); // 50,000 * 1.85
    });
  });
}
