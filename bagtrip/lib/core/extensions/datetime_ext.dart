/// Date / duration helpers used across trip detail, cards and home.
///
/// Before this extension each caller rolled its own arithmetic:
///
/// ```dart
/// var nights = a.checkOut!.difference(a.checkIn!).inDays;
/// if (nights < 1) nights = 1;
/// ```
///
/// ...which is easy to get off-by-one wrong and duplicated in 5+ card
/// widgets. Prefer these extensions.
extension DateTimeExt on DateTime {
  /// Whole days from `this` to now. Negative if `this` is in the past.
  ///
  /// Uses calendar-day truncation so "tomorrow at 01:00" counts as
  /// 1 day away no matter what time it currently is.
  int get daysUntilNow {
    final now = DateTime.now();
    final a = DateTime(year, month, day);
    final b = DateTime(now.year, now.month, now.day);
    return a.difference(b).inDays;
  }

  /// Whole days from now to `this`. Negative if `this` is in the future.
  int get daysSinceNow => -daysUntilNow;

  /// Number of nights between `this` (check-in) and [checkOut].
  ///
  /// Clamped to a minimum of 1 night — a same-day check-in/out still
  /// counts as one night for pricing and summary purposes.
  int nightsUntil(DateTime checkOut) {
    final nights = checkOut.difference(this).inDays;
    return nights < 1 ? 1 : nights;
  }

  /// Flight-duration style formatting: `"2h05"` for the delta between
  /// `this` (departure) and [arrival]. Negative durations clamp to `0h00`.
  String flightDurationTo(DateTime arrival) {
    final diff = arrival.difference(this);
    if (diff.isNegative) return '0h00';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }
}
