import 'package:intl/intl.dart';

abstract class PriceFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00');

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatPiasters(int amountPiasters) {
    return format(amountPiasters / 100);
  }
}