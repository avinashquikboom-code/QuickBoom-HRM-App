// India Standard Time (UTC+5:30) Date Utilities for HopKid HRM Mobile App

class IstDateUtils {
  /// Converts any DateTime to India Standard Time (UTC+5:30)
  static DateTime toIst(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(const Duration(hours: 5, minutes: 30));
  }

  /// Returns current DateTime in IST (UTC+5:30)
  static DateTime nowIst() {
    return DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  /// Parses string or DateTime object and returns DateTime in IST
  static DateTime parseIst(dynamic dateVal) {
    if (dateVal is DateTime) {
      return toIst(dateVal);
    }
    if (dateVal is String) {
      final parsed = DateTime.tryParse(dateVal);
      if (parsed != null) {
        return toIst(parsed);
      }
    }
    return nowIst();
  }

  /// Checks if a given date falls on TODAY in IST (00:00:00 to 23:59:59.999 IST)
  static bool isToday(dynamic dateVal) {
    final istDt = parseIst(dateVal);
    final currentIst = nowIst();
    return istDt.year == currentIst.year &&
        istDt.month == currentIst.month &&
        istDt.day == currentIst.day;
  }

  /// Checks if a given date falls within LAST 7 CALENDAR DAYS (inclusive of today) in IST.
  /// Example: Today = 14 Aug -> 08 Aug to 14 Aug.
  static bool isLast7Days(dynamic dateVal) {
    final istDt = parseIst(dateVal);
    final currentIst = nowIst();

    final todayStart = DateTime.utc(currentIst.year, currentIst.month, currentIst.day);
    final sevenDaysAgoStart = todayStart.subtract(const Duration(days: 6));
    final targetDate = DateTime.utc(istDt.year, istDt.month, istDt.day);

    return (targetDate.isAfter(sevenDaysAgoStart.subtract(const Duration(seconds: 1))) ||
            targetDate.isAtSameMomentAs(sevenDaysAgoStart)) &&
        (targetDate.isBefore(todayStart.add(const Duration(days: 1))));
  }

  /// Checks if a given date falls in CURRENT CALENDAR MONTH in IST (01 Aug to 31 Aug)
  static bool isCurrentMonth(dynamic dateVal) {
    final istDt = parseIst(dateVal);
    final currentIst = nowIst();
    return istDt.year == currentIst.year && istDt.month == currentIst.month;
  }
}
