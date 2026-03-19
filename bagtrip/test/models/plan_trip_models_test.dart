import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/models/budget_range.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetRange', () {
    test('JSON round-trip', () {
      const original = BudgetRange(min: 100.0, max: 500.0);
      final json = original.toJson();
      final decoded = BudgetRange.fromJson(json);
      expect(decoded, original);
    });

    test('fromJson with snake_case keys', () {
      final result = BudgetRange.fromJson({'min': 50.0, 'max': 200.0});
      expect(result.min, 50.0);
      expect(result.max, 200.0);
    });
  });

  group('LocationResult', () {
    test('JSON round-trip', () {
      const original = LocationResult(
        name: 'Paris Charles de Gaulle',
        iataCode: 'CDG',
        city: 'Paris',
        countryCode: 'FR',
        countryName: 'France',
        subType: 'AIRPORT',
      );
      final json = original.toJson();
      final decoded = LocationResult.fromJson(json);
      expect(decoded, original);
    });

    test('fromJson with Amadeus-style keys', () {
      final result = LocationResult.fromJson({
        'name': 'Barcelona',
        'iataCode': 'BCN',
        'city': 'Barcelona',
        'countryCode': 'ES',
        'countryName': 'Spain',
        'subType': 'CITY',
      });
      expect(result.name, 'Barcelona');
      expect(result.iataCode, 'BCN');
      expect(result.countryName, 'Spain');
    });

    test('defaults for optional fields', () {
      final result = LocationResult.fromJson({
        'name': 'Test',
        'iataCode': 'TST',
      });
      expect(result.city, '');
      expect(result.countryCode, '');
      expect(result.countryName, '');
      expect(result.subType, '');
    });
  });

  group('AiDestination', () {
    test('JSON round-trip', () {
      const original = AiDestination(
        city: 'Tokyo',
        country: 'Japan',
        iata: 'TYO',
        lat: 35.6762,
        lon: 139.6503,
        matchReason: 'Perfect for spring',
        weatherSummary: 'Mild, cherry blossom season',
        topActivities: ['Temple visit', 'Ramen tour'],
        estimatedBudgetRange: BudgetRange(min: 1200.0, max: 2500.0),
      );
      final json = original.toJson();
      final decoded = AiDestination.fromJson(json);
      expect(decoded, original);
    });

    test('defaults for optional fields', () {
      final result = AiDestination.fromJson({
        'city': 'Rome',
        'country': 'Italy',
      });
      expect(result.iata, isNull);
      expect(result.topActivities, isEmpty);
      expect(result.estimatedBudgetRange, isNull);
    });
  });

  group('TripPlan', () {
    test('JSON round-trip', () {
      const original = TripPlan(
        destinationCity: 'Lisbon',
        destinationCountry: 'Portugal',
        destinationIata: 'LIS',
        durationDays: 5,
        budgetEur: 800,
        highlights: ['Pastéis de Belém', 'Alfama district'],
        accommodationName: 'Hotel Lisboa',
        accommodationPrice: 350.0,
        dayProgram: ['Day 1: Belém', 'Day 2: Alfama'],
        dayDescriptions: ['Visit the tower', 'Explore the streets'],
        dayCategories: ['CULTURE', 'CULTURE'],
        essentialItems: ['Sunscreen', 'Walking shoes'],
        essentialReasons: ['Sunny weather', 'Cobblestone streets'],
      );
      final json = original.toJson();
      final decoded = TripPlan.fromJson(json);
      expect(decoded, original);
    });

    test('defaults produce valid empty plan', () {
      const plan = TripPlan();
      expect(plan.destinationCity, '');
      expect(plan.durationDays, 7);
      expect(plan.budgetEur, 0);
      expect(plan.highlights, isEmpty);
      expect(plan.dayProgram, isEmpty);
      expect(plan.budgetBreakdown, isEmpty);
    });
  });
}
