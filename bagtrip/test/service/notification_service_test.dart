// Keys must match the snake_case names produced by _$AppNotificationFromJson.
// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _response({
  required String path,
  required int statusCode,
  Object? data,
}) => Response(
  requestOptions: RequestOptions(path: path),
  statusCode: statusCode,
  data: data,
);

Map<String, dynamic> _notifJson({String id = 'n-1', bool isRead = false}) =>
    <String, dynamic>{
      'id': id,
      'type': 'TRIP_REMINDER',
      'title': 'Reminder',
      'body': 'Check your trip',
      'data': <String, dynamic>{},
      'is_read': isRead,
      'trip_id': 'trip-1',
      'sent_at': '2025-01-01T00:00:00.000Z',
      'created_at': '2025-01-01T00:00:00.000Z',
    };

void main() {
  late _MockApiClient mockApiClient;
  late NotificationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = NotificationRepositoryImpl(apiClient: mockApiClient);
  });

  group('NotificationRepositoryImpl', () {
    // ── getNotifications ────────────────────────────────────────────────

    test('getNotifications parses envelope with items + counters', () async {
      when(
        () => mockApiClient.get(
          '/notifications',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(
          path: '/notifications',
          statusCode: 200,
          data: <String, dynamic>{
            'items': [_notifJson(id: 'n-1'), _notifJson(id: 'n-2')],
            'total': 2,
            'page': 1,
            'limit': 20,
            'totalPages': 1,
            'unreadCount': 1,
          },
        ),
      );

      final result = await repository.getNotifications();

      expect(result, isA<Success>());
      final map = (result as Success).data as Map<String, dynamic>;
      expect((map['items'] as List).length, 2);
      expect(map['total'], 2);
      expect(map['unreadCount'], 1);
    });

    test(
      'getNotifications falls back to snake_case counter keys if present',
      () async {
        when(
          () => mockApiClient.get(
            '/notifications',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => _response(
            path: '/notifications',
            statusCode: 200,
            data: <String, dynamic>{
              'items': [_notifJson()],
              'total_pages': 4,
              'unread_count': 7,
            },
          ),
        );

        final result = await repository.getNotifications();
        final map = (result as Success).data as Map<String, dynamic>;
        expect(map['totalPages'], 4);
        expect(map['unreadCount'], 7);
      },
    );

    test('getNotifications returns Failure on non-200', () async {
      when(
        () => mockApiClient.get(
          '/notifications',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => _response(
          path: '/notifications',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      expect(await repository.getNotifications(), isA<Failure>());
    });

    test('getNotifications maps DioException to Failure', () async {
      when(
        () => mockApiClient.get(
          '/notifications',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(await repository.getNotifications(), isA<Failure>());
    });

    // ── getUnreadCount (best-effort: always Success) ────────────────────

    test('getUnreadCount returns the count on 200', () async {
      when(() => mockApiClient.get('/notifications/unread-count')).thenAnswer(
        (_) async => _response(
          path: '/notifications/unread-count',
          statusCode: 200,
          data: <String, dynamic>{'count': 5},
        ),
      );

      final result = await repository.getUnreadCount();
      expect(result, isA<Success>());
      expect((result as Success).data, 5);
    });

    test('getUnreadCount returns 0 on non-200 (best-effort)', () async {
      when(() => mockApiClient.get('/notifications/unread-count')).thenAnswer(
        (_) async => _response(
          path: '/notifications/unread-count',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );

      final result = await repository.getUnreadCount();
      expect(result, isA<Success>());
      expect((result as Success).data, 0);
    });

    test('getUnreadCount returns 0 on exception (best-effort)', () async {
      when(
        () => mockApiClient.get('/notifications/unread-count'),
      ).thenThrow(Exception('boom'));

      final result = await repository.getUnreadCount();
      expect(result, isA<Success>());
      expect((result as Success).data, 0);
    });

    // ── markAsRead ──────────────────────────────────────────────────────

    test('markAsRead returns the updated notification on 200', () async {
      when(() => mockApiClient.patch('/notifications/n-1/read')).thenAnswer(
        (_) async => _response(
          path: '/notifications/n-1/read',
          statusCode: 200,
          data: _notifJson(isRead: true),
        ),
      );

      final result = await repository.markAsRead('n-1');
      expect(result, isA<Success>());
      expect((result as Success).data.isRead, isTrue);
    });

    test('markAsRead returns Failure on non-200', () async {
      when(() => mockApiClient.patch('/notifications/n-1/read')).thenAnswer(
        (_) async => _response(
          path: '/notifications/n-1/read',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );
      expect(await repository.markAsRead('n-1'), isA<Failure>());
    });

    test('markAsRead maps DioException to Failure', () async {
      when(() => mockApiClient.patch('/notifications/n-1/read')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications/n-1/read'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.markAsRead('n-1'), isA<Failure>());
    });

    // ── markAllAsRead ───────────────────────────────────────────────────

    test('markAllAsRead returns the updated count on 200', () async {
      when(() => mockApiClient.post('/notifications/read-all')).thenAnswer(
        (_) async => _response(
          path: '/notifications/read-all',
          statusCode: 200,
          data: <String, dynamic>{'updated': 3},
        ),
      );

      final result = await repository.markAllAsRead();
      expect(result, isA<Success>());
      expect((result as Success).data, 3);
    });

    test('markAllAsRead returns Success(0) on non-200', () async {
      when(() => mockApiClient.post('/notifications/read-all')).thenAnswer(
        (_) async => _response(
          path: '/notifications/read-all',
          statusCode: 500,
          data: <String, dynamic>{},
        ),
      );
      final result = await repository.markAllAsRead();
      expect(result, isA<Success>());
      expect((result as Success).data, 0);
    });

    test('markAllAsRead maps DioException to Failure', () async {
      when(() => mockApiClient.post('/notifications/read-all')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications/read-all'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.markAllAsRead(), isA<Failure>());
    });

    // ── device tokens (best-effort: always Success) ─────────────────────

    test('registerDeviceToken is best-effort', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            _response(path: '/device-tokens', statusCode: 200, data: null),
      );

      expect(
        await repository.registerDeviceToken('fcm-1', platform: 'ios'),
        isA<Success>(),
      );

      final captured = verify(
        () => mockApiClient.post(
          '/device-tokens',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload['fcmToken'], 'fcm-1');
      expect(payload['platform'], 'ios');
    });

    test('registerDeviceToken swallows errors', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/device-tokens'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(await repository.registerDeviceToken('fcm-1'), isA<Success>());
    });

    test('unregisterDeviceToken is best-effort', () async {
      when(() => mockApiClient.delete('/device-tokens/fcm-1')).thenAnswer(
        (_) async => _response(
          path: '/device-tokens/fcm-1',
          statusCode: 200,
          data: null,
        ),
      );

      expect(await repository.unregisterDeviceToken('fcm-1'), isA<Success>());
    });

    test('unregisterDeviceToken swallows errors', () async {
      when(() => mockApiClient.delete('/device-tokens/fcm-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/device-tokens/fcm-1'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.unregisterDeviceToken('fcm-1'), isA<Success>());
    });
  });
}
