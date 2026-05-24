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

  group('updateManualFlight', () {
    test('returns Success(ManualFlight) on 200', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: manualFlightJson,
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
        ),
      );

      final result = await repo.updateManualFlight('trip-1', 'fl-1', {
        'airline': 'Air France Updated',
      });

      expect(result, isA<Success>());
      final flight = (result as Success).data;
      expect(flight.id, 'fl-1');
      expect(flight.flightNumber, 'AF123');
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
        ),
      );

      final result = await repo.updateManualFlight('trip-1', 'fl-1', {
        'airline': 'Air France Updated',
      });

      expect(result, isA<Failure>());
    });
  });

  group('searchFlightsPersisted', () {
    test('returns Success(PersistedFlightSearchResult) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'searchId': 'search-1',
            'offers': [],
            'amadeusData': [
              {
                'id': '1',
                'price': {'grandTotal': '100.00'},
              },
            ],
            'dictionaries': {
              'carriers': {'AF': 'Air France'},
            },
          },
          statusCode: 201,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/searches',
          ),
        ),
      );

      final result = await repo.searchFlightsPersisted(
        tripId: 'trip-1',
        originIata: 'CDG',
        destinationIata: 'JFK',
        departureDate: '2027-06-01',
        adults: 1,
      );

      expect(result, isA<Success>());
      final data = (result as Success).data;
      expect(data.searchId, 'search-1');
      expect(data.amadeusData, hasLength(1));
      expect(data.dictionaries?['carriers']?['AF'], 'Air France');
    });
  });

  group('searchMultiDestFlights', () {
    test('returns Success(List<PersistedFlightSearchResult>) on 201', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'segments': [
              {
                'searchId': 'search-1',
                'offers': [],
                'amadeusData': [
                  {'id': '1'},
                ],
                'dictionaries': null,
              },
              {
                'searchId': 'search-2',
                'offers': [],
                'amadeusData': [
                  {'id': '2'},
                ],
                'dictionaries': null,
              },
            ],
          },
          statusCode: 201,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/searches/multi',
          ),
        ),
      );

      final result = await repo.searchMultiDestFlights(
        tripId: 'trip-1',
        segments: [
          {
            'originIata': 'CDG',
            'destinationIata': 'NRT',
            'departureDate': '2027-06-01',
          },
          {
            'originIata': 'NRT',
            'destinationIata': 'BKK',
            'departureDate': '2027-06-05',
          },
        ],
        adults: 1,
      );

      expect(result, isA<Success>());
      final data = (result as Success).data;
      expect(data, hasLength(2));
      expect(data[0].searchId, 'search-1');
      expect(data[1].searchId, 'search-2');
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

  // ── Phase B reinforcement ─────────────────────────────────────────────

  group('getManualFlights — reinforcement', () {
    test('items envelope accepted', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [manualFlightJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );
      expect(await repo.getManualFlights('trip-1'), isA<Success>());
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );
      expect(await repo.getManualFlights('trip-1'), isA<Failure>());
    });
  });

  group('createManualFlight — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
        ),
      );
      expect(
        await repo.createManualFlight('trip-1', <String, dynamic>{}),
        isA<Failure>(),
      );
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/flights/manual'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.createManualFlight('trip-1', <String, dynamic>{}),
        isA<Failure>(),
      );
    });
  });

  group('updateManualFlight — reinforcement', () {
    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
        ),
      );
      expect(
        await repo.updateManualFlight('trip-1', 'fl-1', {}),
        isA<Failure>(),
      );
    });
  });

  group('deleteManualFlight — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
        ),
      );
      expect(await repo.deleteManualFlight('trip-1', 'fl-1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/manual/fl-1',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteManualFlight('trip-1', 'fl-1'), isA<Failure>());
    });
  });

  group('searchFlightsPersisted — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/searches',
          ),
        ),
      );
      expect(
        await repo.searchFlightsPersisted(
          tripId: 'trip-1',
          originIata: 'CDG',
          destinationIata: 'JFK',
          departureDate: '2027-06-01',
          adults: 1,
        ),
        isA<Failure>(),
      );
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/trips/trip-1/flights/searches',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.searchFlightsPersisted(
          tripId: 'trip-1',
          originIata: 'CDG',
          destinationIata: 'JFK',
          departureDate: '2027-06-01',
          adults: 1,
        ),
        isA<Failure>(),
      );
    });
  });

  group('lookupFlight — reinforcement', () {
    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/travel/flights/AF123/info'),
        ),
      );
      expect(await repo.lookupFlight('AF123'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/travel/flights/AF123/info'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.lookupFlight('AF123'), isA<Failure>());
    });
  });
}
