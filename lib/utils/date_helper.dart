import 'package:intl/intl.dart';

/// A utility class for formatting [DateTime] objects into human-readable strings.
class DateHelper {
  /// Formats a date as a day of the month (e.g., "15").
  static String formatDay(DateTime date) => DateFormat('d').format(date);
  
  /// Formats a date as a short month name (e.g., "Mar").
  static String formatMonth(DateTime date) => DateFormat('MMM').format(date);
  
  /// Formats a date as day and short month (e.g., "15 Mar").
  static String formatShort(DateTime date) => DateFormat('d MMM').format(date);
  
  /// Formats a date range into a single string (e.g., "15 Mar - 20 Mar").
  static String formatRange(DateTime start, DateTime end) =>
      '${formatShort(start)} - ${formatShort(end)}';
}

