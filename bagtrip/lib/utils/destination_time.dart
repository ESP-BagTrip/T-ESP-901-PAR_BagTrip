import 'package:timezone/timezone.dart' as tz;

/// Returns the current DateTime in the destination's timezone.
/// Falls back to device local time if timezone is null or unrecognized.
DateTime nowInDestination(String? destinationTimezone) {
  if (destinationTimezone == null || destinationTimezone.isEmpty) {
    return DateTime.now();
  }
  try {
    final location = tz.getLocation(destinationTimezone);
    final tzNow = tz.TZDateTime.now(location);
    return DateTime(
      tzNow.year,
      tzNow.month,
      tzNow.day,
      tzNow.hour,
      tzNow.minute,
      tzNow.second,
    );
  } catch (_) {
    return DateTime.now();
  }
}
