import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late TripRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = TripRepositoryImpl(apiClient: mockApiClient);
  });

  final tripJson = {
    'id': 'trip-1',
    'user_id': 'u1',
    'title': 'Paris',
    'status': 'draft',
  };

  group('createTrip', () {
    test('success (201) returns Success(Trip)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tripJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      final result = await repo.createTrip(title: 'Paris');

      expect(result, isA<Success>());
      final trip = (result as Success).data;
      expect(trip.id, 'trip-1');
      expect(trip.userId, 'u1');
      expect(trip.title, 'Paris');
      expect(trip.status, TripStatus.draft);
    });
  });

  group('getTrips', () {
    test('list response returns Success(List<Trip>)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [tripJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      final result = await repo.getTrips();

      expect(result, isA<Success>());
      final trips = (result as Success).data;
      expect(trips, hasLength(1));
      expect(trips.first.id, 'trip-1');
    });

    test('items response returns Success(List<Trip>)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [tripJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      final result = await repo.getTrips();

      expect(result, isA<Success>());
      final trips = (result as Success).data;
      expect(trips, hasLength(1));
      expect(trips.first.title, 'Paris');
    });
  });

  group('getGroupedTrips', () {
    test('success returns Success(TripGrouped)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'ongoing': <Map<String, dynamic>>[],
            'planned': [
              {
                'id': 'trip-2',
                'user_id': 'u1',
                'title': 'Tokyo',
                'status': 'planned',
              },
            ],
            'completed': <Map<String, dynamic>>[],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/grouped'),
        ),
      );

      final result = await repo.getGroupedTrips();

      expect(result, isA<Success>());
      final grouped = (result as Success).data;
      expect(grouped.ongoing, isEmpty);
      expect(grouped.planned, hasLength(1));
      expect(grouped.planned.first.title, 'Tokyo');
      expect(grouped.completed, isEmpty);
    });
  });

  group('getTripHome', () {
    test('success returns Success(TripHome)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'trip': tripJson,
            'stats': {'baggageCount': 5, 'totalExpenses': 250.0},
            'features': [
              {
                'id': 'activities',
                'label': 'Activities',
                'icon': 'activity',
                'route': '/activities',
                'enabled': true,
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/home'),
        ),
      );

      final result = await repo.getTripHome('trip-1');

      expect(result, isA<Success>());
      final tripHome = (result as Success).data;
      expect(tripHome.trip.id, 'trip-1');
      expect(tripHome.stats.baggageCount, 5);
      expect(tripHome.stats.totalExpenses, 250.0);
      expect(tripHome.features, hasLength(1));
      expect(tripHome.features.first.id, 'activities');
    });
  });

  group('deleteTrip', () {
    test('success (204) returns Success(null)', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );

      final result = await repo.deleteTrip('trip-1');

      expect(result, isA<Success>());
    });

    test('DioException 404 returns Failure(NotFoundError)', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1'),
          response: Response(
            statusCode: 404,
            data: {'detail': 'trip not found'},
            requestOptions: RequestOptions(path: '/trips/trip-1'),
          ),
        ),
      );

      final result = await repo.deleteTrip('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<NotFoundError>());
      expect(error.statusCode, 404);
      expect(error.message, 'trip not found');
    });

    test('non-2xx status returns Failure(UnknownError)', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );

      final result = await repo.deleteTrip('trip-1');
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('non-Dio exception wrapped in UnknownError', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(const FormatException('bad'));
      expect(await repo.deleteTrip('trip-1'), isA<Failure>());
    });
  });

  // ── Phase B reinforcement: remaining methods + error paths ────────────

  group('createTrip — reinforcement', () {
    test('posts only the provided optional fields', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 201,
          data: tripJson,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      await repo.createTrip(
        title: 'Rome',
        destinationIata: 'FCO',
        startDate: DateTime(2025, 10, 1, 13, 30),
        endDate: DateTime(2025, 10, 8, 22, 15),
        nbTravelers: 2,
        budgetTotal: 1500,
        origin: 'manual',
      );

      final captured = verify(
        () => mockApiClient.post(
          '/trips',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['title'], 'Rome');
      expect(payload['destinationIata'], 'FCO');
      // Dates should be truncated to midnight before being serialized.
      expect(payload['startDate'], contains('2025-10-01T00:00:00'));
      expect(payload['endDate'], contains('2025-10-08T00:00:00'));
      expect(payload['nbTravelers'], 2);
      expect(payload['budgetTotal'], 1500);
      expect(payload['origin'], 'manual');
      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('coverImageUrl'), isFalse);
    });

    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );
      expect(await repo.createTrip(title: 'x'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.createTrip(title: 'x'), isA<Failure>());
    });
  });

  group('getTrips — reinforcement', () {
    test('unknown payload shape returns empty Success', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      final result = await repo.getTrips();
      expect((result as Success).data, isEmpty);
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
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );
      expect(await repo.getTrips(), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getTrips(), isA<Failure>());
    });
  });

  group('getTripsPaginated', () {
    test('parses total_pages fallback', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [tripJson],
            'total': 12,
            'page': 2,
            'total_pages': 3,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );

      final result = await repo.getTripsPaginated(page: 2, status: 'planned');
      expect(result, isA<Success>());
      final paginated = (result as Success).data;
      expect(paginated.items, hasLength(1));
      expect(paginated.total, 12);
      expect(paginated.totalPages, 3);
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
          requestOptions: RequestOptions(path: '/trips'),
        ),
      );
      expect(await repo.getTripsPaginated(), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getTripsPaginated(), isA<Failure>());
    });
  });

  group('getTripById', () {
    test('unwraps {trip: {...}} envelope', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'trip': tripJson},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );
      final result = await repo.getTripById('trip-1');
      expect(result, isA<Success>());
      expect((result as Success).data.id, 'trip-1');
    });

    test('accepts raw map body', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tripJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );
      expect(await repo.getTripById('trip-1'), isA<Success>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );
      expect(await repo.getTripById('trip-1'), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getTripById('trip-1'), isA<Failure>());
    });
  });

  group('updateTripStatus', () {
    test('returns Success on 200', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tripJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/status'),
        ),
      );
      expect(await repo.updateTripStatus('trip-1', 'planned'), isA<Success>());
    });

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
          requestOptions: RequestOptions(path: '/trips/trip-1/status'),
        ),
      );
      expect(await repo.updateTripStatus('trip-1', 'planned'), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1/status'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.updateTripStatus('trip-1', 'planned'), isA<Failure>());
    });
  });

  group('updateTrip', () {
    test('returns Success on 200', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: tripJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );

      expect(
        await repo.updateTrip('trip-1', {'title': 'Rome'}),
        isA<Success>(),
      );
    });

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
          requestOptions: RequestOptions(path: '/trips/trip-1'),
        ),
      );
      expect(await repo.updateTrip('trip-1', {'title': 'x'}), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.updateTrip('trip-1', {'title': 'x'}), isA<Failure>());
    });
  });

  group('getGroupedTrips — reinforcement', () {
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
          requestOptions: RequestOptions(path: '/trips/grouped'),
        ),
      );
      expect(await repo.getGroupedTrips(), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/grouped'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getGroupedTrips(), isA<Failure>());
    });
  });

  group('getTripHome — reinforcement', () {
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
          requestOptions: RequestOptions(path: '/trips/trip-1/home'),
        ),
      );
      expect(await repo.getTripHome('trip-1'), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1/home'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getTripHome('trip-1'), isA<Failure>());
    });
  });
}
