import 'package:bagtrip/trip_detail/helpers/trip_departure_countdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 1, 10);

  test('returns null when start is null or in the past', () {
    expect(TripDepartureCountdown.fromStartDate(null, now: now), isNull);
    expect(
      TripDepartureCountdown.fromStartDate(
        now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      isNull,
    );
  });

  test('uses calendar days when more than 48h away', () {
    final start = now.add(const Duration(days: 26, hours: 5));
    final countdown = TripDepartureCountdown.fromStartDate(start, now: now);
    expect(countdown?.mode, TripDepartureCountdownMode.days);
    expect(countdown?.days, 26);
  });

  test('uses hours and minutes when under 48h away', () {
    final start = now.add(const Duration(hours: 17, minutes: 34));
    final countdown = TripDepartureCountdown.fromStartDate(start, now: now);
    expect(countdown?.mode, TripDepartureCountdownMode.hoursMinutes);
    expect(countdown?.hours, 17);
    expect(countdown?.minutes, 34);
  });
}
