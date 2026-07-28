import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateTimeFormat.format(date);
  }

  static String formatIsoDate(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static int calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
