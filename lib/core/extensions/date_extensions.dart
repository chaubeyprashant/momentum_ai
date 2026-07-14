import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String get formatted => DateFormat('MMM d, yyyy').format(this);
  String get dayName => DateFormat('EEEE').format(this);
  String get shortDate => DateFormat('MMM d').format(this);
  String get timeFormatted => DateFormat('h:mm a').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  int get daysUntil => difference(DateTime.now()).inDays;
}
