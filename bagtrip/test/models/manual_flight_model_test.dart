import 'package:bagtrip/models/manual_flight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ManualFlight JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'id': 'flight-1',
        'trip_id': 'trip-1',
        'flight_number': 'AF1234',
        'airline': 'Air France',
        'departure_airport': 'CDG',
        'arrival_airport': 'NRT',
        'departure_date': '2024-07-15T10:30:00.000',
        'arrival_date': '2024-07-16T06:45:00.000',
        'price': 850.00,
        'currency': 'EUR',
        'notes': 'Window seat booked',
        'flight_type': 'OUTBOUND',
        'created_at': '2024-05-01T10:00:00.000',
        'updated_at': '2024-05-02T12:00:00.000',
      };

      final first = ManualFlight.fromJson(json);
      final serialized = first.toJson();
      final second = ManualFlight.fromJson(serialized);

      expect(second, first);
      expect(second.id, 'flight-1');
      expect(second.tripId, 'trip-1');
      expect(second.flightNumber, 'AF1234');
      expect(second.airline, 'Air France');
      expect(second.departureAirport, 'CDG');
      expect(second.arrivalAirport, 'NRT');
      expect(second.departureDate, DateTime.parse('2024-07-15T10:30:00.000'));
      expect(second.arrivalDate, DateTime.parse('2024-07-16T06:45:00.000'));
      expect(second.price, 850.00);
      expect(second.currency, 'EUR');
      expect(second.notes, 'Window seat booked');
      expect(second.flightType, 'OUTBOUND');
      expect(second.createdAt, DateTime.parse('2024-05-01T10:00:00.000'));
      expect(second.updatedAt, DateTime.parse('2024-05-02T12:00:00.000'));
    });

    test('fromJson with minimal fields applies defaults', () {
      final json = <String, dynamic>{
        'id': 'flight-min',
        'trip_id': 'trip-min',
        'flight_number': 'LH999',
      };

      final model = ManualFlight.fromJson(json);

      expect(model.id, 'flight-min');
      expect(model.tripId, 'trip-min');
      expect(model.flightNumber, 'LH999');
      expect(model.airline, isNull);
      expect(model.departureAirport, isNull);
      expect(model.arrivalAirport, isNull);
      expect(model.departureDate, isNull);
      expect(model.arrivalDate, isNull);
      expect(model.price, isNull);
      expect(model.currency, isNull);
      expect(model.notes, isNull);
      expect(model.flightType, 'MAIN');
      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'id': 'flight-nulls',
        'trip_id': 'trip-nulls',
        'flight_number': 'BA456',
        'airline': null,
        'departure_airport': null,
        'arrival_airport': null,
        'departure_date': null,
        'arrival_date': null,
        'price': null,
        'currency': null,
        'notes': null,
        'created_at': null,
        'updated_at': null,
      };

      final first = ManualFlight.fromJson(json);
      final serialized = first.toJson();
      final second = ManualFlight.fromJson(serialized);

      expect(second, first);
      expect(second.airline, isNull);
      expect(second.departureAirport, isNull);
      expect(second.arrivalAirport, isNull);
      expect(second.departureDate, isNull);
      expect(second.arrivalDate, isNull);
      expect(second.price, isNull);
      expect(second.currency, isNull);
      expect(second.notes, isNull);
      expect(second.flightType, 'MAIN');
      expect(second.createdAt, isNull);
      expect(second.updatedAt, isNull);
    });
  });
}
