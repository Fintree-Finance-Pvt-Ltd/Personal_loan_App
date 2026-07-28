import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pl_customer_app/app/app.dart';

void main() {
  testWidgets('PlCustomerApp builds splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlCustomerApp(),
      ),
    );
    expect(find.text('Personal Loan Platform'), findsOneWidget);
  });
}
