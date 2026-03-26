import 'package:bagtrip/plan_trip/helpers/budget_estimation.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateBudget', () {
    test('backpacker solo 7 days', () {
      final result = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 1,
        days: 7,
      );
      expect(result.min, 30.0 * 7);
      expect(result.max, 60.0 * 7);
    });

    test('comfortable 2 travelers 14 days', () {
      final result = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 2,
        days: 14,
      );
      expect(result.min, 80.0 * 2 * 14);
      expect(result.max, 150.0 * 2 * 14);
    });

    test('premium 1 traveler 3 days (weekend)', () {
      final result = estimateBudget(
        preset: BudgetPreset.premium,
        nbTravelers: 1,
        days: 3,
      );
      expect(result.min, 200.0 * 3);
      expect(result.max, 400.0 * 3);
    });

    test('noLimit 4 travelers 21 days', () {
      final result = estimateBudget(
        preset: BudgetPreset.noLimit,
        nbTravelers: 4,
        days: 21,
      );
      expect(result.min, 400.0 * 4 * 21);
      expect(result.max, 1000.0 * 4 * 21);
    });

    test('min is always less than max', () {
      for (final preset in BudgetPreset.values) {
        final result = estimateBudget(preset: preset, nbTravelers: 1, days: 1);
        expect(result.min, lessThan(result.max));
      }
    });

    test('scales linearly with travelers', () {
      final solo = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 1,
        days: 7,
      );
      final duo = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 2,
        days: 7,
      );
      expect(duo.min, solo.min * 2);
      expect(duo.max, solo.max * 2);
    });

    test('scales linearly with days', () {
      final week = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 1,
        days: 7,
      );
      final twoWeeks = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 1,
        days: 14,
      );
      expect(twoWeeks.min, week.min * 2);
      expect(twoWeeks.max, week.max * 2);
    });
  });
}
