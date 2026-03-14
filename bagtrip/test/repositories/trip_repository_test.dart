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
    'userId': 'u1',
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
                'userId': 'u1',
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
  });
}
