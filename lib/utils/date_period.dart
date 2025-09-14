class MonthPeriod {
  final DateTime start;
  final DateTime end;
  const MonthPeriod(this.start, this.end);
}

/// Compute a monthly period with a custom first day (1..28).
/// If today is before the firstDay, the period starts on that day of the previous month.
MonthPeriod computeCustomMonthPeriod(DateTime now, int firstDay) {
  final d = firstDay.clamp(1, 28);
  // Determine period start
  DateTime start;
  if (now.day >= d) {
    start = DateTime(now.year, now.month, d);
  } else {
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    start = DateTime(prevMonth.year, prevMonth.month, d);
  }
  final end = DateTime(start.year, start.month + 1, d);
  return MonthPeriod(start, end);
}

