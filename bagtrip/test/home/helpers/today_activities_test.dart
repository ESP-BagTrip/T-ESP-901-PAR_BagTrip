import 'package:bagtrip/home/helpers/today_activities.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('classifyTodayActivities', () {
    final today = DateTime(2024, 6, 15, 14, 30);
    final todayDate = DateTime(2024, 6, 15);
    final tomorrowDate = DateTime(2024, 6, 16);
    final yesterdayDate = DateTime(2024, 6, 14);

    test('empty input returns isEmpty', () {
      final result = classifyTodayActivities(allActivities: [], now: today);
      expect(result.isEmpty, true);
      expect(result.allDayActivities, isEmpty);
      expect(result.timedActivities, isEmpty);
      expect(result.nextActivity, isNull);
      expect(result.tomorrowActivities, isEmpty);
    });

    test('filters today only — ignores yesterday and tomorrow', () {
      final activities = [
        makeActivity(id: '1', date: yesterdayDate, title: 'Yesterday'),
        makeActivity(id: '2', date: todayDate, title: 'Today'),
        makeActivity(id: '3', date: tomorrowDate, title: 'Tomorrow'),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.timedActivities.length, 1);
      expect(result.timedActivities.first.title, 'Today');
    });

    test('separates allDay from timed', () {
      final activities = [
        makeActivity(
          id: '1',
          date: todayDate,
          startTime: null,
          title: 'AllDay',
        ),
        makeActivity(
          id: '2',
          date: todayDate,
          startTime: '10:00',
          title: 'Timed',
        ),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.allDayActivities.length, 1);
      expect(result.allDayActivities.first.title, 'AllDay');
      expect(result.timedActivities.length, 1);
      expect(result.timedActivities.first.title, 'Timed');
    });

    test('sorts timed by startTime ascending', () {
      final activities = [
        makeActivity(id: '1', date: todayDate, startTime: '16:00', title: 'C'),
        makeActivity(id: '2', date: todayDate, title: 'A'),
        makeActivity(id: '3', date: todayDate, startTime: '12:00', title: 'B'),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.timedActivities[0].title, 'A');
      expect(result.timedActivities[1].title, 'B');
      expect(result.timedActivities[2].title, 'C');
    });

    test('nextActivity is first after now (mid-day)', () {
      // now is 14:30
      final activities = [
        makeActivity(id: '1', date: todayDate, title: 'Past'),
        makeActivity(
          id: '2',
          date: todayDate,
          startTime: '14:00',
          title: 'AlsoPast',
        ),
        makeActivity(
          id: '3',
          date: todayDate,
          startTime: '15:00',
          title: 'Next',
        ),
        makeActivity(
          id: '4',
          date: todayDate,
          startTime: '18:00',
          title: 'Later',
        ),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.nextActivity, isNotNull);
      expect(result.nextActivity!.title, 'Next');
    });

    test('nextActivity null when all past', () {
      final activities = [
        makeActivity(id: '1', date: todayDate),
        makeActivity(id: '2', date: todayDate, startTime: '12:00'),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.nextActivity, isNull);
    });

    test('nextActivity is first when all future', () {
      final earlyMorning = DateTime(2024, 6, 15, 7);
      final activities = [
        makeActivity(id: '1', date: todayDate, title: 'First'),
        makeActivity(
          id: '2',
          date: todayDate,
          startTime: '12:00',
          title: 'Second',
        ),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: earlyMorning,
      );

      expect(result.nextActivity!.title, 'First');
    });

    test('tomorrow activities computed correctly', () {
      final activities = [
        makeActivity(id: '1', date: todayDate),
        makeActivity(
          id: '2',
          date: tomorrowDate,
          startTime: '14:00',
          title: 'T2',
        ),
        makeActivity(
          id: '3',
          date: tomorrowDate,
          startTime: '10:00',
          title: 'T1',
        ),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.tomorrowActivities.length, 2);
      expect(result.tomorrowActivities[0].title, 'T1');
      expect(result.tomorrowActivities[1].title, 'T2');
    });

    test('edge: no tomorrow activities on last day', () {
      // Only today activities, no tomorrow
      final activities = [
        makeActivity(id: '1', date: todayDate, startTime: '10:00'),
      ];

      final result = classifyTodayActivities(
        allActivities: activities,
        now: today,
      );

      expect(result.tomorrowActivities, isEmpty);
    });
  });
}
