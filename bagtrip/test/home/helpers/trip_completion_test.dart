import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tripCompletion', () {
    test('returns 0 for null trip', () {
      expect(tripCompletion(null), 0);
    });

    test('returns 0 when all fields are null/default', () {
      const trip = Trip(id: 'empty');
      expect(tripCompletion(trip), 0);
    });

    test('returns 40 when 2/5 fields are filled', () {
      final trip = Trip(
        id: 'partial',
        startDate: DateTime(2024, 6),
        destinationName: 'Paris',
      );
      expect(tripCompletion(trip), 40);
    });

    test('returns 100 when all fields are filled', () {
      final trip = Trip(
        id: 'full',
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 7),
        destinationName: 'Paris',
        nbTravelers: 2,
        budgetTotal: 1500,
      );
      expect(tripCompletion(trip), 100);
    });

    test('empty destinationName does not count', () {
      final trip = Trip(
        id: 'empty-dest',
        startDate: DateTime(2024, 6),
        destinationName: '',
      );
      expect(tripCompletion(trip), 20);
    });

    test('nbTravelers = 0 does not count', () {
      final trip = Trip(
        id: 'zero-travelers',
        startDate: DateTime(2024, 6),
        nbTravelers: 0,
      );
      expect(tripCompletion(trip), 20);
    });

    test('budgetTotal = 0 does not count', () {
      final trip = Trip(
        id: 'zero-budget',
        startDate: DateTime(2024, 6),
        budgetTotal: 0,
      );
      expect(tripCompletion(trip), 20);
    });

    test('returns 60 when 3/5 fields are filled', () {
      final trip = Trip(
        id: 'three',
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 7),
        nbTravelers: 3,
      );
      expect(tripCompletion(trip), 60);
    });
  });
}
