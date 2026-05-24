import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/trip_detail/helpers/flight_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  group('deriveFlightStatus', () {
    test('all 5 fields present → confirmed', () {
      final flight = makeManualFlight(
        departureDate: DateTime(2024, 6, 12, 8, 30),
        arrivalDate: DateTime(2024, 6, 12, 14, 45),
      );
      expect(deriveFlightStatus(flight), FlightDisplayStatus.confirmed);
    });

    test('missing departureAirport → pending', () {
      final flight = makeManualFlight(departureAirport: null);
      expect(deriveFlightStatus(flight), FlightDisplayStatus.pending);
    });

    test('missing arrivalAirport → pending', () {
      final flight = makeManualFlight(arrivalAirport: null);
      expect(deriveFlightStatus(flight), FlightDisplayStatus.pending);
    });

    test('missing airline → pending', () {
      final flight = makeManualFlight(airline: null);
      expect(deriveFlightStatus(flight), FlightDisplayStatus.pending);
    });

    test('missing departureDate → pending', () {
      const flight = ManualFlight(
        id: 'f1',
        tripId: 'trip-1',
        flightNumber: 'AF123',
        airline: 'Air France',
        departureAirport: 'CDG',
        arrivalAirport: 'JFK',
      );
      expect(deriveFlightStatus(flight), FlightDisplayStatus.pending);
    });

    test('missing arrivalDate → pending', () {
      final flight = ManualFlight(
        id: 'f1',
        tripId: 'trip-1',
        flightNumber: 'AF123',
        airline: 'Air France',
        departureAirport: 'CDG',
        arrivalAirport: 'JFK',
        departureDate: DateTime(2024, 6, 12, 8, 30),
      );
      expect(deriveFlightStatus(flight), FlightDisplayStatus.pending);
    });
  });

  group('flightStatusColor', () {
    test('confirmed → success', () {
      expect(
        flightStatusColor(FlightDisplayStatus.confirmed),
        AppColors.success,
      );
    });

    test('pending → warning', () {
      expect(flightStatusColor(FlightDisplayStatus.pending), AppColors.warning);
    });
  });
}
