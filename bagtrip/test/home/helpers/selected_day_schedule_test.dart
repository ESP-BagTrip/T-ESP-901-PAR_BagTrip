import 'package:bagtrip/home/helpers/selected_day_schedule.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildScheduleForSelectedDay', () {
    final trip = Trip(
      id: 't1',
      title: 'Test',
      startDate: DateTime(2025, 4, 10),
      endDate: DateTime(2025, 4, 12),
    );

    final activities = [
      Activity(
        id: 'a1',
        tripId: 't1',
        title: 'Morning',
        date: DateTime(2025, 4, 11),
        startTime: '09:00',
        endTime: '10:00',
      ),
    ];

    test('past day: no current/next', () {
      final r = buildScheduleForSelectedDay(
        allActivities: activities,
        trip: trip,
        selectedDayIndex0: 1,
        totalDays: 3,
        now: DateTime(2025, 4, 15),
      );
      expect(r.dayKind, SelectedDayKind.beforeToday);
      expect(r.currentActivity, isNull);
      expect(r.isEmpty, isFalse);
    });

    test('future day: no current', () {
      final r = buildScheduleForSelectedDay(
        allActivities: activities,
        trip: trip,
        selectedDayIndex0: 2,
        totalDays: 3,
        now: DateTime(2025, 4, 10),
      );
      expect(r.dayKind, SelectedDayKind.afterToday);
      expect(r.currentActivity, isNull);
    });

    test('today sets dayKind today', () {
      final r = buildScheduleForSelectedDay(
        allActivities: activities,
        trip: trip,
        selectedDayIndex0: 1,
        totalDays: 3,
        now: DateTime(2025, 4, 11, 8),
      );
      expect(r.dayKind, SelectedDayKind.today);
    });
  });

  group('defaultSelectedDayIndex0', () {
    test('clamps to trip range', () {
      final trip = Trip(
        id: 't1',
        title: 'T',
        startDate: DateTime(2025),
        endDate: DateTime(2025, 1, 3),
      );
      expect(
        defaultSelectedDayIndex0(
          trip: trip,
          totalDays: 3,
          now: DateTime(2024, 12, 31),
        ),
        0,
      );
    });
  });
}
