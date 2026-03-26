import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/transport_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late TransportRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = TransportRepositoryImpl(apiClient: mockApiClient);
  });

  final manualFlightJson = {
    'id': 'fl-1',
    'trip_id': 'trip-1',
    'flight_number': 'AF123',
    'airline': 'Air France',
    'departure_airport': 'CDG',
    'arrival_airport': 'JFK',
    'flight_type': 'MAIN',
  };

  final flightInfoJson = {
    'flightIata': 'AF123',
    'airlineIata': 'AF',
    'airlineName': 'Air France',
    'status': 'scheduled',
    'departureIata': 'CDG',
    'departureTerminal': '2E',
    'departureTime': '2024-06-01T10:00:00',
    'arrivalIata': 'JFK',
    'arrivalTerminal': '1',
    'arrivalTime': '2024-06-01T13:00:00',
  };

  group('getManualFlights', () {
    test('returns Success(List<ManualFlight>) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [manualFlightJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Success>());
      final flights = (result as Success).data;
      expect(flights, hasLength(1));
      expect(flights.first.id, 'fl-1');
      expect(flights.first.flightNumber, 'AF123');
      expect(flights.first.airline, 'Air France');
    });
  });

  group('createManualFlight', () {
    test('returns Success(ManualFlight) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: manualFlightJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );

      final result = await repo.createManualFlight('trip-1', {
        'flight_number': 'AF123',
        'airline': 'Air France',
        'departure_airport': 'CDG',
        'arrival_airport': 'JFK',
      });

      expect(result, isA<Success>());
      final flight = (result as Success).data;
      expect(flight.id, 'fl-1');
      expect(flight.flightNumber, 'AF123');
    });
  });

  group('deleteManualFlight', () {
    test('returns Success(null) on 204', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
        ),
      );

      final result = await repo.deleteManualFlight('trip-1', 'fl-1');

      expect(result, isA<Success>());
    });
  });

  group('lookupFlight', () {
    test('returns Success(FlightInfo) on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: flightInfoJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/travel/flights/AF123/info'),
        ),
      );

      final result = await repo.lookupFlight('AF123');

      expect(result, isA<Success>());
      final info = (result as Success).data;
      expect(info.flightIata, 'AF123');
      expect(info.airlineName, 'Air France');
      expect(info.departureIata, 'CDG');
      expect(info.arrivalIata, 'JFK');
    });
  });

  group('getManualFlights error handling', () {
    test('DioException connectionTimeout returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );

      final result = await repo.getManualFlights('trip-1');

      expect(result, isA<Failure>());
    });
  });
}
