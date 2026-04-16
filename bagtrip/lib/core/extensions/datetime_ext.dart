/// Date/time helpers used across the app.
extension DateTimeExt on DateTime {
  /// Number of calendar nights between this date and [other].
  int nightsUntil(DateTime other) {
    final from = DateTime(year, month, day);
    final to = DateTime(other.year, other.month, other.day);
    return to.difference(from).inDays;
  }

  /// Number of full days between [this] and now (absolute).
  int get daysUntilNow {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(year, month, day)).inDays.abs();
  }

  /// Human-readable flight duration between [this] and [arrival].
  String flightDurationTo(DateTime arrival) {
    final diff = arrival.difference(this);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
