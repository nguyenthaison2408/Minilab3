import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _vietnameseDate = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dayOfWeekFormat = DateFormat('E, dd/MM', 'vi');

  static String format(DateTime date) {
    return _vietnameseDate.format(date);
  }

  static String formatWithTime(DateTime date) {
    return _displayDateTime.format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  static DateTime? parse(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          int p1 = int.parse(parts[0]);
          int p2 = int.parse(parts[1]);
          int p3 = int.parse(parts[2]);
          if (p1 > 1000) {
            // YYYY/MM/DD
            return DateTime(p1, p2, p3);
          } else {
            // DD/MM/YYYY
            return DateTime(p3, p2, p1);
          }
        }
      } else if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          int p1 = int.parse(parts[0]);
          int p2 = int.parse(parts[1]);
          int p3 = int.parse(parts[2]);
          if (p1 > 1000) {
            // YYYY-MM-DD
            return DateTime(p1, p2, p3);
          } else {
            // DD-MM-YYYY
            return DateTime(p3, p2, p1);
          }
        }
      }
    } catch (_) {}
    return null;
  }
}

