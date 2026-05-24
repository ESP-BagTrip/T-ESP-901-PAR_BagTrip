import 'package:bagtrip/models/flight_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlightInfo JSON roundtrip', () {
    test('fromJson -> toJson -> fromJson produces identical object', () {
      final json = <String, dynamic>{
        'flightIata': 'AF1234',
        'airlineIata': 'AF',
        'airlineName': 'Air France',
        'status': 'active',
        'departureIata': 'CDG',
        'departureTerminal': '2E',
        'departureGate': 'K42',
        'departureTime': '2024-07-15T10:30:00.000',
        'departureActual': '2024-07-15T10:35:00.000',
        'departureDelay': 5,
        'arrivalIata': 'NRT',
        'arrivalTerminal': '1',
        'arrivalGate': 'A12',
        'arrivalTime': '2024-07-16T06:45:00.000',
        'arrivalActual': '2024-07-16T06:50:00.000',
        'arrivalDelay': 5,
      };

      final first = FlightInfo.fromJson(json);
      final serialized = first.toJson();
      final second = FlightInfo.fromJson(serialized);

      expect(second, first);
      expect(second.flightIata, 'AF1234');
      expect(second.airlineIata, 'AF');
      expect(second.airlineName, 'Air France');
      expect(second.status, 'active');
      expect(second.departureIata, 'CDG');
      expect(second.departureTerminal, '2E');
      expect(second.departureGate, 'K42');
      expect(second.departureTime, '2024-07-15T10:30:00.000');
      expect(second.departureActual, '2024-07-15T10:35:00.000');
      expect(second.departureDelay, 5);
      expect(second.arrivalIata, 'NRT');
      expect(second.arrivalTerminal, '1');
      expect(second.arrivalGate, 'A12');
      expect(second.arrivalTime, '2024-07-16T06:45:00.000');
      expect(second.arrivalActual, '2024-07-16T06:50:00.000');
      expect(second.arrivalDelay, 5);
    });

    test('fromJson with minimal fields (empty JSON)', () {
      final json = <String, dynamic>{};

      final model = FlightInfo.fromJson(json);

      expect(model.flightIata, isNull);
      expect(model.airlineIata, isNull);
      expect(model.airlineName, isNull);
      expect(model.status, isNull);
      expect(model.departureIata, isNull);
      expect(model.departureTerminal, isNull);
      expect(model.departureGate, isNull);
      expect(model.departureTime, isNull);
      expect(model.departureActual, isNull);
      expect(model.departureDelay, isNull);
      expect(model.arrivalIata, isNull);
      expect(model.arrivalTerminal, isNull);
      expect(model.arrivalGate, isNull);
      expect(model.arrivalTime, isNull);
      expect(model.arrivalActual, isNull);
      expect(model.arrivalDelay, isNull);
    });

    test('handles nullable fields set to null', () {
      final json = <String, dynamic>{
        'flightIata': null,
        'airlineIata': null,
        'airlineName': null,
        'status': null,
        'departureIata': null,
        'departureTerminal': null,
        'departureGate': null,
        'departureTime': null,
        'departureActual': null,
        'departureDelay': null,
        'arrivalIata': null,
        'arrivalTerminal': null,
        'arrivalGate': null,
        'arrivalTime': null,
        'arrivalActual': null,
        'arrivalDelay': null,
      };

      final first = FlightInfo.fromJson(json);
      final serialized = first.toJson();
      final second = FlightInfo.fromJson(serialized);

      expect(second, first);
      expect(second.flightIata, isNull);
      expect(second.airlineIata, isNull);
      expect(second.departureDelay, isNull);
      expect(second.arrivalDelay, isNull);
    });
  });
}
