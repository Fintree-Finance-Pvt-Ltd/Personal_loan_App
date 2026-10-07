import 'package:flutter_test/flutter_test.dart';
import 'package:pl_customer_app/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('English translations return correct values', () {
      const loc = AppLocalizations('en');
      expect(loc.isHindi, false);
      expect(loc.tr('hello'), 'Hello,');
      expect(loc.tr('active_loan_details'), 'Active Loan Details');
      expect(loc.tr('pay_now'), 'Pay Now');
      expect(loc.tr('view_rps'), 'View RPS Schedule');
      expect(loc.tr('app_language'), 'App Language');
    });

    test('Hindi translations return correct values', () {
      const loc = AppLocalizations('hi');
      expect(loc.isHindi, true);
      expect(loc.tr('hello'), 'नमस्ते,');
      expect(loc.tr('active_loan_details'), 'सक्रिय ऋण विवरण');
      expect(loc.tr('pay_now'), 'अभी भुगतान करें');
      expect(loc.tr('view_rps'), 'भुगतान अनुसूची (RPS) देखें');
      expect(loc.tr('app_language'), 'ऐप की भाषा (Language)');
    });

    test('Fallback to key or English when key is missing', () {
      const loc = AppLocalizations('hi');
      expect(loc.tr('non_existent_key'), 'non_existent_key');
    });
  });
}
