import 'package:bagtrip/trip_detail/helpers/day_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('groupActivitiesByDay', () {
    test('3-day trip with mixed activities → correct buckets', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: '09:30'),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '14:00'),
        makeActivity(id: 'a3', date: DateTime(2024, 6, 2), startTime: '19:00'),
        makeActivity(id: 'a4', date: DateTime(2024, 6, 3), startTime: null),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 3,
      );

      expect(result.length, 3);
      expect(result[1]!.morning.length, 1);
      expect(result[1]!.morning.first.id, 'a1');
      expect(result[1]!.afternoon.length, 1);
      expect(result[1]!.afternoon.first.id, 'a2');
      expect(result[2]!.evening.length, 1);
      expect(result[2]!.evening.first.id, 'a3');
      expect(result[3]!.allDay.length, 1);
      expect(result[3]!.allDay.first.id, 'a4');
    });

    test('09:30 → morning, 14:00 → afternoon, 19:00 → evening', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: '09:30'),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '14:00'),
        makeActivity(id: 'a3', date: DateTime(2024, 6), startTime: '19:00'),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 1,
      );

      expect(result[1]!.morning.length, 1);
      expect(result[1]!.afternoon.length, 1);
      expect(result[1]!.evening.length, 1);
    });

    test('null startTime → allDay', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: null),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 1,
      );

      expect(result[1]!.allDay.length, 1);
      expect(result[1]!.morning.isEmpty, true);
      expect(result[1]!.afternoon.isEmpty, true);
      expect(result[1]!.evening.isEmpty, true);
    });

    test('activity outside trip range → excluded', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 5, 31), startTime: '10:00'),
        makeActivity(id: 'a2', date: DateTime(2024, 6, 4), startTime: '10:00'),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 3,
      );

      expect(result[1]!.isEmpty, true);
      expect(result[2]!.isEmpty, true);
      expect(result[3]!.isEmpty, true);
    });

    test('empty list → empty DayActivities per day', () {
      final start = DateTime(2024, 6);
      final result = groupActivitiesByDay(
        activities: [],
        tripStartDate: start,
        totalDays: 3,
      );

      expect(result.length, 3);
      for (var d = 1; d <= 3; d++) {
        expect(result[d]!.isEmpty, true);
        expect(result[d]!.totalCount, 0);
      }
    });

    test('exactly 12:00 → afternoon, 17:00 → evening', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: '12:00'),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '17:00'),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 1,
      );

      expect(result[1]!.morning.isEmpty, true);
      expect(result[1]!.afternoon.length, 1);
      expect(result[1]!.afternoon.first.id, 'a1');
      expect(result[1]!.evening.length, 1);
      expect(result[1]!.evening.first.id, 'a2');
    });

    test('single-day trip', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: '08:00'),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '15:00'),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 1,
      );

      expect(result.length, 1);
      expect(result[1]!.morning.length, 1);
      expect(result[1]!.afternoon.length, 1);
      expect(result[1]!.totalCount, 2);
    });

    test('sorted within blocks by startTime ascending', () {
      final start = DateTime(2024, 6);
      final activities = [
        makeActivity(id: 'a3', date: DateTime(2024, 6), startTime: '11:30'),
        makeActivity(id: 'a1', date: DateTime(2024, 6), startTime: '08:00'),
        makeActivity(id: 'a2', date: DateTime(2024, 6), startTime: '10:00'),
      ];

      final result = groupActivitiesByDay(
        activities: activities,
        tripStartDate: start,
        totalDays: 1,
      );

      final morning = result[1]!.morning;
      expect(morning.length, 3);
      expect(morning[0].id, 'a1');
      expect(morning[1].id, 'a2');
      expect(morning[2].id, 'a3');
    });

    test('DayActivities.isEmpty returns true when all lists empty', () {
      const day = DayActivities();
      expect(day.isEmpty, true);
      expect(day.totalCount, 0);
    });

    test('DayActivities.isEmpty returns false when any list non-empty', () {
      final day = DayActivities(morning: [makeActivity()]);
      expect(day.isEmpty, false);
      expect(day.totalCount, 1);
    });
  });
}
