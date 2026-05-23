// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late NotificationRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    repo = NotificationRepositoryImpl(apiClient: mockApiClient);
  });

  final prefsJson = {
    'push_enabled': true,
    'flight_reminders': false,
    'activity_reminders': true,
    'trip_updates': true,
    'budget_alerts': false,
    'social': true,
  };

  group('getNotificationPreferences', () {
    test('GETs /notifications/preferences and parses snake_case', () async {
      when(() => mockApiClient.get(any())).thenAnswer(
        (_) async => Response(
          data: prefsJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/notifications/preferences'),
        ),
      );

      final result = await repo.getNotificationPreferences();

      expect(result, isA<Success>());
      final prefs = (result as Success).data as NotificationPreferences;
      expect(prefs.pushEnabled, true);
      expect(prefs.flightReminders, false);
      expect(prefs.budgetAlerts, false);
      verify(() => mockApiClient.get('/notifications/preferences')).called(1);
    });

    test('DioException returns Failure', () async {
      when(() => mockApiClient.get(any())).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/notifications/preferences'),
        ),
      );

      final result = await repo.getNotificationPreferences();

      expect(result, isA<Failure>());
    });
  });

  group('updateNotificationPreferences', () {
    test('PATCHes with snake_case body and parses response', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: prefsJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/notifications/preferences'),
        ),
      );

      const prefs = NotificationPreferences(
        pushEnabled: true,
        flightReminders: false,
        activityReminders: true,
        tripUpdates: true,
        budgetAlerts: false,
        social: true,
      );

      final result = await repo.updateNotificationPreferences(prefs);

      expect(result, isA<Success>());

      final captured = verify(
        () => mockApiClient.patch(
          captureAny(),
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured;
      expect(captured[0], '/notifications/preferences');
      final body = captured[1] as Map<String, dynamic>;
      expect(body['push_enabled'], true);
      expect(body['flight_reminders'], false);
      expect(body['budget_alerts'], false);
      expect(body.containsKey('pushEnabled'), false);
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
          requestOptions: RequestOptions(path: '/notifications/preferences'),
        ),
      );

      final result = await repo.updateNotificationPreferences(
        const NotificationPreferences(),
      );

      expect(result, isA<Failure>());
    });
  });
}
