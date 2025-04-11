import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = '₹'}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    ).format(amount);
  }

  static String formatCompact(double amount, {String symbol = '₹'}) {
    if (amount >= 1000) {
      return NumberFormat.compactCurrency(
        symbol: symbol,
        decimalDigits: 1,
      ).format(amount);
    } else {
      return format(amount, symbol: symbol);
    }
  }

  static String formatWithoutSymbol(double amount) {
    return NumberFormat.decimalPattern().format(amount);
  }
} 