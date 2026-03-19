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
  });
}
