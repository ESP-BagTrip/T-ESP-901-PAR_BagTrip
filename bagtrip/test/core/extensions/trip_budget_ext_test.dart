// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/extensions/trip_budget_ext.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _trip({double? budget}) => Trip(id: 't', budgetTotal: budget);

void main() {
  group('TripBudgetExt (B22)', () {
    test('hasBudget is false when budgetTotal is null', () {
      expect(_trip(budget: null).hasBudget, isFalse);
    });

    test('hasBudget is false when budgetTotal is zero', () {
      expect(_trip(budget: 0).hasBudget, isFalse);
    });

    test('hasBudget is false when budgetTotal is negative', () {
      expect(_trip(budget: -100).hasBudget, isFalse);
    });

    test('hasBudget is true when budgetTotal is positive', () {
      expect(_trip(budget: 1500).hasBudget, isTrue);
    });

    test('safeBudgetTotal returns 0.0 when null', () {
      expect(_trip(budget: null).safeBudgetTotal, 0.0);
    });

    test('safeBudgetTotal returns the value when set', () {
      expect(_trip(budget: 1500).safeBudgetTotal, 1500.0);
    });
  });
}
