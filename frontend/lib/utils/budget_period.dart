DateTime getCurrentPeriodStart(int cycleDay) {
  final now = DateTime.now();
  int year = now.year;
  int month = now.month;

  if (now.day < cycleDay) {
    month -= 1;
    if (month == 0) {
      month = 12;
      year -= 1;
    }
  }

  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final actualDay = cycleDay > lastDayOfMonth ? lastDayOfMonth : cycleDay;

  return DateTime(year, month, actualDay);
}

DateTime getPeriodEnd(DateTime periodStart) {
  int year = periodStart.year;
  int month = periodStart.month + 1;
  if (month == 13) {
    month = 1;
    year += 1;
  }

  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final actualDay = periodStart.day > lastDayOfMonth
      ? lastDayOfMonth
      : periodStart.day;

  return DateTime(year, month, actualDay).subtract(const Duration(days: 1));
}

String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
