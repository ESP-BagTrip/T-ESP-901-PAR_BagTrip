import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/activity_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late ActivityRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = ActivityRepositoryImpl(apiClient: mockApiClient);
  });

  final activityJson = {
    'id': 'a1',
    'trip_id': 'trip-1',
    'title': 'Visit',
    'date': '2024-06-01T00:00:00.000',
  };

  group('getActivities', () {
    test('list response returns Success(List<Activity>)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [activityJson],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Success>());
      final activities = (result as Success).data;
      expect(activities, hasLength(1));
      expect(activities.first.id, 'a1');
      expect(activities.first.tripId, 'trip-1');
      expect(activities.first.title, 'Visit');
    });

    test('items response returns Success(List<Activity>)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [activityJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );

      final result = await repo.getActivities('trip-1');

      expect(result, isA<Success>());
      final activities = (result as Success).data;
      expect(activities, hasLength(1));
      expect(activities.first.title, 'Visit');
    });
  });

  group('createActivity', () {
    test('success (201) returns Success(Activity)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: activityJson,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );

      final result = await repo.createActivity('trip-1', {
        'title': 'Visit',
        'date': '2024-06-01T00:00:00.000',
      });

      expect(result, isA<Success>());
      final activity = (result as Success).data;
      expect(activity.id, 'a1');
      expect(activity.title, 'Visit');
    });
  });

  group('deleteActivity', () {
    test('success (204) returns Success(null)', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
        ),
      );

      final result = await repo.deleteActivity('trip-1', 'a1');

      expect(result, isA<Success>());
    });
  });

  group('suggestActivities', () {
    test('success returns Success(List<Map>)', () async {
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
            'activities': [
              {'title': 'Suggested'},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/suggest',
          ),
        ),
      );

      final result = await repo.suggestActivities('trip-1');

      expect(result, isA<Success>());
      final suggestions = (result as Success).data;
      expect(suggestions, hasLength(1));
      expect(suggestions.first['title'], 'Suggested');
    });

    test('DioException 402 returns Failure(QuotaExceededError)', () async {
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
            path: '/trips/trip-1/activities/suggest',
          ),
          response: Response(
            statusCode: 402,
            data: {'detail': 'quota exceeded'},
            requestOptions: RequestOptions(
              path: '/trips/trip-1/activities/suggest',
            ),
          ),
        ),
      );

      final result = await repo.suggestActivities('trip-1');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<QuotaExceededError>());
      expect(error.statusCode, 402);
      expect(error.message, 'quota exceeded');
    });

    test('passes day query parameter through when provided', () async {
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
            'activities': [
              {'title': 'x'},
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/suggest',
          ),
        ),
      );

      await repo.suggestActivities('trip-1', day: 3);

      verify(
        () => mockApiClient.post(
          '/trips/trip-1/activities/suggest',
          queryParameters: {'day': 3},
        ),
      ).called(1);
    });

    test('invalid shape returns Failure(ServerError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{},
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/suggest',
          ),
        ),
      );

      final result = await repo.suggestActivities('trip-1');
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<ServerError>());
    });

    test('non-200 returns Failure', () async {
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
            path: '/trips/trip-1/activities/suggest',
          ),
        ),
      );
      expect(await repo.suggestActivities('trip-1'), isA<Failure>());
    });
  });

  // ── Phase B reinforcement ─────────────────────────────────────────────

  group('getActivities — reinforcement', () {
    test('invalid shape returns Failure(ServerError)', () async {
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );
      final result = await repo.getActivities('trip-1');
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<ServerError>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );
      expect(await repo.getActivities('trip-1'), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getActivities('trip-1'), isA<Failure>());
    });
  });

  group('getActivitiesPaginated', () {
    test('returns parsed paginated response on 200', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'items': [activityJson],
            'total': 42,
            'page': 2,
            'totalPages': 5,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );
      final result = await repo.getActivitiesPaginated('trip-1', page: 2);
      expect(result, isA<Success>());
      expect((result as Success).data.totalPages, 5);
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );
      expect(await repo.getActivitiesPaginated('trip-1'), isA<Failure>());
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.getActivitiesPaginated('trip-1'), isA<Failure>());
    });
  });

  group('createActivity — reinforcement', () {
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
        ),
      );
      expect(
        await repo.createActivity('trip-1', {'title': 'x'}),
        isA<Failure>(),
      );
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.createActivity('trip-1', {'title': 'x'}),
        isA<Failure>(),
      );
    });
  });

  group('updateActivity', () {
    test('returns Success on 200', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: activityJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
        ),
      );
      expect(
        await repo.updateActivity('trip-1', 'a1', {'title': 'New'}),
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
        ),
      );
      expect(
        await repo.updateActivity('trip-1', 'a1', {'title': 'x'}),
        isA<Failure>(),
      );
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
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.updateActivity('trip-1', 'a1', {'title': 'x'}),
        isA<Failure>(),
      );
    });
  });

  group('deleteActivity — reinforcement', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
        ),
      );
      expect(await repo.deleteActivity('trip-1', 'a1'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/trips/trip-1/activities/a1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteActivity('trip-1', 'a1'), isA<Failure>());
    });
  });

  group('batchUpdateActivities', () {
    test('returns Success(list) on 200', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: [activityJson],
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/batch',
          ),
        ),
      );
      final result = await repo.batchUpdateActivities(
        'trip-1',
        ['a1'],
        {'validationStatus': 'VALIDATED'},
      );
      expect(result, isA<Success>());
      expect((result as Success).data.length, 1);
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/batch',
          ),
        ),
      );
      expect(
        await repo.batchUpdateActivities('trip-1', ['a1'], {}),
        isA<Failure>(),
      );
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
          requestOptions: RequestOptions(
            path: '/trips/trip-1/activities/batch',
          ),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
        await repo.batchUpdateActivities('trip-1', ['a1'], {}),
        isA<Failure>(),
      );
    });
  });
}
