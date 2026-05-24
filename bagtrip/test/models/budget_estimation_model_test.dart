import 'package:bagtrip/models/budget_estimation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetEstimation JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'accommodationPerNight': 95.0,
        'mealsPerDayPerPerson': 45.0,
        'localTransportPerDay': 15.0,
        'activitiesTotal': 300.0,
        'totalMin': 1200.0,
        'totalMax': 1800.0,
        'currency': 'USD',
        'breakdownNotes': 'Budget includes museum passes',
      };

      final first = BudgetEstimation.fromJson(json);
      final serialized = first.toJson();
      final second = BudgetEstimation.fromJson(serialized);

      expect(second, first);
      expect(second.accommodationPerNight, 95.0);
      expect(second.mealsPerDayPerPerson, 45.0);
      expect(second.localTransportPerDay, 15.0);
      expect(second.activitiesTotal, 300.0);
      expect(second.totalMin, 1200.0);
      expect(second.totalMax, 1800.0);
      expect(second.currency, 'USD');
      expect(second.breakdownNotes, 'Budget includes museum passes');
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{};

      final model = BudgetEstimation.fromJson(json);

      expect(model.currency, 'EUR');
      expect(model.accommodationPerNight, isNull);
      expect(model.mealsPerDayPerPerson, isNull);
      expect(model.localTransportPerDay, isNull);
      expect(model.activitiesTotal, isNull);
      expect(model.totalMin, isNull);
      expect(model.totalMax, isNull);
      expect(model.breakdownNotes, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'accommodationPerNight': null,
        'mealsPerDayPerPerson': null,
        'localTransportPerDay': null,
        'activitiesTotal': null,
        'totalMin': null,
        'totalMax': null,
        'breakdownNotes': null,
      };

      final first = BudgetEstimation.fromJson(json);
      final serialized = first.toJson();
      final second = BudgetEstimation.fromJson(serialized);

      expect(second, first);
      expect(second.currency, 'EUR');
      expect(second.accommodationPerNight, isNull);
      expect(second.mealsPerDayPerPerson, isNull);
      expect(second.localTransportPerDay, isNull);
      expect(second.activitiesTotal, isNull);
      expect(second.totalMin, isNull);
      expect(second.totalMax, isNull);
      expect(second.breakdownNotes, isNull);
    });
  });
}
