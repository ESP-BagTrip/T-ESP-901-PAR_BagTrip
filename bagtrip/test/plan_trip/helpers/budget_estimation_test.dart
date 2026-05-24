import 'package:bagtrip/plan_trip/helpers/budget_estimation.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('estimateBudget', () {
    test('backpacker 1 traveler 7 days → 210-420', () {
      final range = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 1,
        days: 7,
      );
      expect(range.min, 210.0);
      expect(range.max, 420.0);
    });

    test('comfortable 2 travelers 14 days → 2240-4200', () {
      final range = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 2,
        days: 14,
      );
      expect(range.min, 2240.0);
      expect(range.max, 4200.0);
    });

    test('premium 3 travelers 3 days → 1800-3600', () {
      final range = estimateBudget(
        preset: BudgetPreset.premium,
        nbTravelers: 3,
        days: 3,
      );
      expect(range.min, 1800.0);
      expect(range.max, 3600.0);
    });

    test('noLimit 1 traveler 21 days → 8400-21000', () {
      final range = estimateBudget(
        preset: BudgetPreset.noLimit,
        nbTravelers: 1,
        days: 21,
      );
      expect(range.min, 8400.0);
      expect(range.max, 21000.0);
    });

    test('linear scaling with travelers', () {
      final one = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 1,
        days: 7,
      );
      final three = estimateBudget(
        preset: BudgetPreset.comfortable,
        nbTravelers: 3,
        days: 7,
      );
      expect(three.min, one.min * 3);
      expect(three.max, one.max * 3);
    });

    test('linear scaling with days', () {
      final oneWeek = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 2,
        days: 7,
      );
      final twoWeeks = estimateBudget(
        preset: BudgetPreset.backpacker,
        nbTravelers: 2,
        days: 14,
      );
      expect(twoWeeks.min, oneWeek.min * 2);
      expect(twoWeeks.max, oneWeek.max * 2);
    });
  });
}
