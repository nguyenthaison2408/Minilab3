import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 1,
  );

  static String formatVND(double amount) {
    return _vndFormat.format(amount);
  }

  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount);
  }
}

