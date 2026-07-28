import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _currencyDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatAmount(dynamic amount, {bool showDecimals = false}) {
    if (amount == null) return '₹0';
    num val = 0;
    if (amount is num) {
      val = amount;
    } else if (amount is String) {
      val = num.tryParse(amount) ?? 0;
    }
    return showDecimals ? _currencyDecimalFormat.format(val) : _currencyFormat.format(val);
  }
}
