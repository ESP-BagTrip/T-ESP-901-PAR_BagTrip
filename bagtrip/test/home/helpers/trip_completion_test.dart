import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tripCompletion', () {
    test('returns 0 for null trip', () {
      expect(tripCompletion(null), 0);
    });

    test('returns 0 when completionPercentage is default', () {
      const trip = Trip(id: 'empty');
      expect(tripCompletion(trip), 0);
    });

    test('returns server-computed completionPercentage', () {
      const trip = Trip(id: 'partial', completionPercentage: 33);
      expect(tripCompletion(trip), 33);
    });

    test('returns 100 when completionPercentage is 100', () {
      const trip = Trip(id: 'full', completionPercentage: 100);
      expect(tripCompletion(trip), 100);
    });
  });
}
