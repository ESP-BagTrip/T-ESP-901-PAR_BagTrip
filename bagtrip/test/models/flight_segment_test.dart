import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlightSegment', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = <String, dynamic>{
          'departureAirport': {'code': 'CDG', 'name': 'Charles de Gaulle'},
          'arrivalAirport': {'code': 'JFK', 'name': 'John F. Kennedy'},
          'departureDate': '2024-06-01T10:00:00.000',
        };

        final segment = FlightSegment.fromJson(json);

        expect(segment.departureAirport, {
          'code': 'CDG',
          'name': 'Charles de Gaulle',
        });
        expect(segment.arrivalAirport, {
          'code': 'JFK',
          'name': 'John F. Kennedy',
        });
        expect(
          segment.departureDate,
          DateTime.parse('2024-06-01T10:00:00.000'),
        );
      });

      test('parses with null fields', () {
        final json = <String, dynamic>{};

        final segment = FlightSegment.fromJson(json);

        expect(segment.departureAirport, isNull);
        expect(segment.arrivalAirport, isNull);
        expect(segment.departureDate, isNull);
      });
    });

    group('toJson', () {
      test('roundtrip produces equal object', () {
        final segment = FlightSegment(
          departureAirport: {'code': 'CDG'},
          arrivalAirport: {'code': 'JFK'},
          departureDate: DateTime.parse('2024-06-01T10:00:00.000'),
        );

        final json = segment.toJson();
        final restored = FlightSegment.fromJson(json);

        expect(restored, segment);
      });
    });
  });
}
