import 'package:bagtrip/home/helpers/contextual_actions_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveContextualActions', () {
    test('during activity returns navigate, expense, photo', () {
      final result = resolveContextualActions(
        hour: 14,
        hasCurrentActivity: true,
        hasNextActivity: false,
      );
      expect(result, [
        QuickActionType.navigate,
        QuickActionType.expense,
        QuickActionType.photo,
      ]);
    });

    test('during activity morning (priority 1 over priority 2)', () {
      final result = resolveContextualActions(
        hour: 9,
        hasCurrentActivity: true,
        hasNextActivity: true,
      );
      expect(result, [
        QuickActionType.navigate,
        QuickActionType.expense,
        QuickActionType.photo,
      ]);
    });

    test('morning before activity returns schedule, weather, checkOut', () {
      final result = resolveContextualActions(
        hour: 8,
        hasCurrentActivity: false,
        hasNextActivity: true,
      );
      expect(result, [
        QuickActionType.todaySchedule,
        QuickActionType.weather,
        QuickActionType.checkOut,
      ]);
    });

    test('afternoon gap returns nextActivity, aiSuggestion, map', () {
      final result = resolveContextualActions(
        hour: 14,
        hasCurrentActivity: false,
        hasNextActivity: true,
      );
      expect(result, [
        QuickActionType.nextActivity,
        QuickActionType.aiSuggestion,
        QuickActionType.map,
      ]);
    });

    test('evening done returns todayExpenses, tomorrow, budget', () {
      final result = resolveContextualActions(
        hour: 20,
        hasCurrentActivity: false,
        hasNextActivity: false,
      );
      expect(result, [
        QuickActionType.todayExpenses,
        QuickActionType.tomorrow,
        QuickActionType.budget,
      ]);
    });

    test('morning no activities returns fallback', () {
      final result = resolveContextualActions(
        hour: 9,
        hasCurrentActivity: false,
        hasNextActivity: false,
      );
      expect(result, [
        QuickActionType.todaySchedule,
        QuickActionType.weather,
        QuickActionType.budget,
      ]);
    });

    test('noon boundary with next activity returns afternoon gap', () {
      final result = resolveContextualActions(
        hour: 12,
        hasCurrentActivity: false,
        hasNextActivity: true,
      );
      expect(result, [
        QuickActionType.nextActivity,
        QuickActionType.aiSuggestion,
        QuickActionType.map,
      ]);
    });

    test('6pm boundary with no activities returns evening', () {
      final result = resolveContextualActions(
        hour: 18,
        hasCurrentActivity: false,
        hasNextActivity: false,
      );
      expect(result, [
        QuickActionType.todayExpenses,
        QuickActionType.tomorrow,
        QuickActionType.budget,
      ]);
    });

    test('always returns exactly 3 items', () {
      for (final hour in [0, 6, 11, 12, 17, 18, 23]) {
        for (final hasCurrent in [true, false]) {
          for (final hasNext in [true, false]) {
            final result = resolveContextualActions(
              hour: hour,
              hasCurrentActivity: hasCurrent,
              hasNextActivity: hasNext,
            );
            expect(
              result.length,
              3,
              reason: 'hour=$hour, current=$hasCurrent, next=$hasNext',
            );
          }
        }
      }
    });
  });
}
