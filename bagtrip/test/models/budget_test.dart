import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetCategory', () {
    test('JSON values are mapped correctly via BudgetItem fromJson', () {
      BudgetItem fromCategory(String category) => BudgetItem.fromJson({
        'id': 'b1',
        'tripId': 't1',
        'label': 'Test',
        'amount': 100.0,
        'category': category,
      });

      expect(fromCategory('FLIGHT').category, BudgetCategory.flight);
      expect(
        fromCategory('ACCOMMODATION').category,
        BudgetCategory.accommodation,
      );
      expect(fromCategory('FOOD').category, BudgetCategory.food);
      expect(fromCategory('ACTIVITY').category, BudgetCategory.activity);
      expect(fromCategory('TRANSPORT').category, BudgetCategory.transport);
      expect(fromCategory('OTHER').category, BudgetCategory.other);
    });

    test('null category defaults to other', () {
      final item = BudgetItem.fromJson({
        'id': 'b1',
        'tripId': 't1',
        'label': 'Test',
        'amount': 50.0,
      });
      expect(item.category, BudgetCategory.other);
    });
  });

  group('BudgetItem', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'id': 'budget-1',
          'tripId': 'trip-1',
          'label': 'Flight to Paris',
          'amount': 450.99,
          'category': 'FLIGHT',
          'date': '2024-06-01T00:00:00.000',
          'isPlanned': false,
          'createdAt': '2024-01-15T10:30:00.000',
          'updatedAt': '2024-02-20T14:00:00.000',
        };

        final item = BudgetItem.fromJson(json);

        expect(item.id, 'budget-1');
        expect(item.tripId, 'trip-1');
        expect(item.label, 'Flight to Paris');
        expect(item.amount, 450.99);
        expect(item.category, BudgetCategory.flight);
        expect(item.date, DateTime.parse('2024-06-01T00:00:00.000'));
        expect(item.isPlanned, false);
        expect(item.createdAt, DateTime.parse('2024-01-15T10:30:00.000'));
        expect(item.updatedAt, DateTime.parse('2024-02-20T14:00:00.000'));
      });

      test('parses with only required fields and applies defaults', () {
        final json = <String, dynamic>{
          'id': 'budget-2',
          'tripId': 'trip-2',
          'label': 'Miscellaneous',
          'amount': 25.0,
        };

        final item = BudgetItem.fromJson(json);

        expect(item.id, 'budget-2');
        expect(item.tripId, 'trip-2');
        expect(item.label, 'Miscellaneous');
        expect(item.amount, 25.0);
        expect(item.category, BudgetCategory.other);
        expect(item.date, isNull);
        expect(item.isPlanned, true);
        expect(item.createdAt, isNull);
        expect(item.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final item = BudgetItem(
          id: 'b-rt',
          tripId: 't-rt',
          label: 'Hotel Stay',
          amount: 800.0,
          category: BudgetCategory.accommodation,
          date: DateTime.parse('2024-06-01T00:00:00.000'),
          createdAt: DateTime.parse('2024-01-01T00:00:00.000'),
          updatedAt: DateTime.parse('2024-03-01T00:00:00.000'),
        );

        final json = item.toJson();
        final restored = BudgetItem.fromJson(json);

        expect(restored, item);
      });

      test('serializes category as uppercase JSON value', () {
        final item = const BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'Bus',
          amount: 10.0,
          category: BudgetCategory.transport,
        );

        final json = item.toJson();
        expect(json['category'], 'TRANSPORT');
      });
    });

    group('equality', () {
      test('two items with same fields are equal', () {
        final b1 = const BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'Test',
          amount: 100.0,
        );
        final b2 = const BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'Test',
          amount: 100.0,
        );
        expect(b1, b2);
      });

      test('two items with different fields are not equal', () {
        final b1 = const BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'Test',
          amount: 100.0,
        );
        final b2 = const BudgetItem(
          id: 'b2',
          tripId: 't1',
          label: 'Test',
          amount: 100.0,
        );
        expect(b1, isNot(b2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final item = const BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'Old',
          amount: 50.0,
        );
        final updated = item.copyWith(
          label: 'New',
          amount: 75.0,
          category: BudgetCategory.food,
        );

        expect(updated.id, 'b1');
        expect(updated.label, 'New');
        expect(updated.amount, 75.0);
        expect(updated.category, BudgetCategory.food);
      });
    });
  });

  group('BudgetSummary', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'totalBudget': 5000.0,
          'totalSpent': 2500.0,
          'remaining': 2500.0,
          'byCategory': {'FLIGHT': 1200.0, 'FOOD': 800.0, 'OTHER': 500.0},
          'percentConsumed': 50.0,
          'alertLevel': 'warning',
          'alertMessage': 'You have spent 50% of your budget',
        };

        final summary = BudgetSummary.fromJson(json);

        expect(summary.totalBudget, 5000.0);
        expect(summary.totalSpent, 2500.0);
        expect(summary.remaining, 2500.0);
        expect(summary.byCategory, {
          'FLIGHT': 1200.0,
          'FOOD': 800.0,
          'OTHER': 500.0,
        });
        expect(summary.percentConsumed, 50.0);
        expect(summary.alertLevel, 'warning');
        expect(summary.alertMessage, 'You have spent 50% of your budget');
      });

      test('parses with no fields and applies defaults', () {
        final json = <String, dynamic>{};

        final summary = BudgetSummary.fromJson(json);

        expect(summary.totalBudget, 0);
        expect(summary.totalSpent, 0);
        expect(summary.remaining, 0);
        expect(summary.byCategory, <String, double>{});
        expect(summary.percentConsumed, isNull);
        expect(summary.alertLevel, isNull);
        expect(summary.alertMessage, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final summary = const BudgetSummary(
          totalBudget: 3000.0,
          totalSpent: 1500.0,
          remaining: 1500.0,
          byCategory: {'FOOD': 500.0, 'TRANSPORT': 1000.0},
          percentConsumed: 50.0,
          alertLevel: 'info',
          alertMessage: 'Half budget used',
        );

        final json = summary.toJson();
        final restored = BudgetSummary.fromJson(json);

        expect(restored, summary);
      });

      test('serializes default values correctly', () {
        const summary = BudgetSummary();

        final json = summary.toJson();

        expect(json['totalBudget'], 0);
        expect(json['totalSpent'], 0);
        expect(json['remaining'], 0);
        expect(json['byCategory'], <String, double>{});
        expect(json['percentConsumed'], isNull);
        expect(json['alertLevel'], isNull);
        expect(json['alertMessage'], isNull);
      });
    });

    group('with alert data', () {
      test('stores percentConsumed, alertLevel, and alertMessage', () {
        final summary = const BudgetSummary(
          totalBudget: 1000.0,
          totalSpent: 900.0,
          remaining: 100.0,
          percentConsumed: 90.0,
          alertLevel: 'danger',
          alertMessage: 'Budget almost exhausted!',
        );

        expect(summary.percentConsumed, 90.0);
        expect(summary.alertLevel, 'danger');
        expect(summary.alertMessage, 'Budget almost exhausted!');
      });
    });

    group('equality', () {
      test('two summaries with same fields are equal', () {
        final s1 = const BudgetSummary(
          totalBudget: 100.0,
          totalSpent: 50.0,
          remaining: 50.0,
        );
        final s2 = const BudgetSummary(
          totalBudget: 100.0,
          totalSpent: 50.0,
          remaining: 50.0,
        );
        expect(s1, s2);
      });

      test('two summaries with different fields are not equal', () {
        final s1 = const BudgetSummary(totalBudget: 100.0);
        final s2 = const BudgetSummary(totalBudget: 200.0);
        expect(s1, isNot(s2));
      });
    });

    group('copyWith', () {
      test('copies with changed fields', () {
        final summary = const BudgetSummary(
          totalBudget: 1000.0,
          totalSpent: 500.0,
          remaining: 500.0,
        );
        final updated = summary.copyWith(
          totalSpent: 750.0,
          remaining: 250.0,
          alertLevel: 'warning',
        );

        expect(updated.totalBudget, 1000.0);
        expect(updated.totalSpent, 750.0);
        expect(updated.remaining, 250.0);
        expect(updated.alertLevel, 'warning');
      });
    });
  });
}
