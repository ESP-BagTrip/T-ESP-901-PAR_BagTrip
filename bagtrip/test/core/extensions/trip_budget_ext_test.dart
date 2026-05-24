// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/extensions/trip_budget_ext.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _trip({double? target}) => Trip(id: 't', budgetTarget: target);

void main() {
  group('TripBudgetExt (B22)', () {
    test('hasBudget is false when budgetTarget is null', () {
      expect(_trip(target: null).hasBudget, isFalse);
    });

    test('hasBudget is false when budgetTarget is zero', () {
      expect(_trip(target: 0).hasBudget, isFalse);
    });

    test('hasBudget is false when budgetTarget is negative', () {
      expect(_trip(target: -100).hasBudget, isFalse);
    });

    test('hasBudget is true when budgetTarget is positive', () {
      expect(_trip(target: 1500).hasBudget, isTrue);
    });

    test('safeBudgetTarget returns 0.0 when null', () {
      expect(_trip(target: null).safeBudgetTarget, 0.0);
    });

    test('safeBudgetTarget returns the value when set', () {
      expect(_trip(target: 1500).safeBudgetTarget, 1500.0);
    });
  });
}
