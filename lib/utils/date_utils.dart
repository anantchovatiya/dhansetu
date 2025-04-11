import 'package:intl/intl.dart';

class DateUtil {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateWithDay(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static DateTime getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static DateTime getWeekEnd(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  static String getMonthName(int month) {
    final date = DateTime(2022, month);
    return DateFormat('MMMM').format(date);
  }

  static List<DateTime> getLast7Days() {
    final today = DateTime.now();
    return List.generate(7, (i) => today.subtract(Duration(days: i))).reversed.toList();
  }

  static List<DateTime> getLast30Days() {
    final today = DateTime.now();
    return List.generate(30, (i) => today.subtract(Duration(days: i))).reversed.toList();
  }

  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) => start.add(Duration(days: i)));
  }

  static List<DateTime> getMonthsInYear(int year) {
    return List.generate(12, (i) => DateTime(year, i + 1, 1));
  }
} 