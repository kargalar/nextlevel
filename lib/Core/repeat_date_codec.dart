class RepeatDateCodec {
  const RepeatDateCodec._();

  static int encodeMonthDay(int month, int day) => month * 100 + day;

  static int encodeDate(DateTime date) => encodeMonthDay(date.month, date.day);

  static List<int> normalizeYearlyDates(
    List<int>? values, {
    DateTime? fallbackDate,
  }) {
    if (values == null || values.isEmpty) {
      return fallbackDate == null ? <int>[] : <int>[encodeDate(fallbackDate)];
    }

    // Backward compatibility: the previous format stored [month, day].
    if (values.length == 2 &&
        values[0] >= 1 &&
        values[0] <= 12 &&
        values[1] >= 1 &&
        values[1] <= 31) {
      return <int>[encodeMonthDay(values[0], values[1])];
    }

    final normalized = values.where(isValidMonthDayCode).toSet().toList()
      ..sort();
    return normalized;
  }

  static bool isValidMonthDayCode(int value) {
    final month = value ~/ 100;
    final day = value % 100;
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    return day <= DateTime(2000, month + 1, 0).day;
  }

  static bool matchesYearlyDate(
    List<int>? values,
    DateTime date, {
    DateTime? fallbackDate,
  }) {
    final dates = normalizeYearlyDates(values, fallbackDate: fallbackDate);
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;

    for (final value in dates) {
      final month = value ~/ 100;
      final day = value % 100;
      final effectiveDay = day > lastDayOfMonth ? lastDayOfMonth : day;
      if (date.month == month && date.day == effectiveDay) {
        return true;
      }
    }
    return false;
  }
}
