import 'package:bagtrip/home/helpers/home_highlight_activity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  final now = DateTime(2024, 6, 15, 14, 30);
  final today = DateTime(2024, 6, 15);

  group('resolveHomeHighlightActivity', () {
    test('returns current activity when in progress', () {
      final current = makeActivity(
        id: 'current',
        title: 'Museum visit',
        date: today,
        startTime: '14:00',
        endTime: '16:00',
      );
      final activities = [
        makeActivity(
          id: 'past',
          title: 'Breakfast',
          date: today,
          startTime: '08:00',
          endTime: '09:00',
        ),
        current,
        makeActivity(
          id: 'later',
          title: 'Dinner',
          date: today,
          startTime: '19:00',
        ),
      ];

      final result = resolveHomeHighlightActivity(activities, now: now);

      expect(result, isNotNull);
      expect(result!.isNow, isTrue);
      expect(result.activity.id, 'current');
    });

    test('returns next activity today when none in progress', () {
      final next = makeActivity(
        id: 'next',
        title: 'Afternoon tour',
        date: today,
        startTime: '16:00',
      );
      final activities = [
        makeActivity(
          id: 'past',
          title: 'Breakfast',
          date: today,
          startTime: '08:00',
          endTime: '09:00',
        ),
        next,
      ];

      final result = resolveHomeHighlightActivity(activities, now: now);

      expect(result, isNotNull);
      expect(result!.isNow, isFalse);
      expect(result.isToday, isTrue);
      expect(result.activity.id, 'next');
    });

    test('returns nearest future-day activity when today is done', () {
      final tomorrow = today.add(const Duration(days: 1));
      final activities = [
        makeActivity(
          id: 'today-done',
          title: 'Morning walk',
          date: today,
          startTime: '08:00',
          endTime: '09:00',
        ),
        makeActivity(
          id: 'tomorrow',
          title: 'Temple visit',
          date: tomorrow,
          startTime: '10:00',
        ),
        makeActivity(
          id: 'later',
          title: 'Beach day',
          date: tomorrow.add(const Duration(days: 2)),
        ),
      ];

      final result = resolveHomeHighlightActivity(
        activities,
        now: DateTime(2024, 6, 15, 20),
      );

      expect(result, isNotNull);
      expect(result!.isTomorrow, isTrue);
      expect(result.activity.id, 'tomorrow');
    });

    test('returns null when no upcoming activities', () {
      final result = resolveHomeHighlightActivity([
        makeActivity(
          id: 'past',
          title: 'Done',
          date: today.subtract(const Duration(days: 1)),
          startTime: '10:00',
        ),
      ], now: now);

      expect(result, isNull);
    });
  });
}
