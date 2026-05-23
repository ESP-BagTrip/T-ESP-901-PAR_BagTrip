import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/notification_page.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<Result<NotificationPage>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        return Success(
          NotificationPage.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('fetch notifications failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        return Success(
          (response.data as Map<String, dynamic>)['count'] as int? ?? 0,
        );
      }
      return const Success(0);
    } catch (e) {
      if (kDebugMode) debugPrint('[BestEffort] getUnreadCount failed: $e');
      return const Success(0);
    }
  }

  @override
  Future<Result<AppNotification>> markAsRead(String notificationId) async {
    try {
      final response = await _apiClient.patch(
        '/notifications/$notificationId/read',
      );
      if (response.statusCode == 200) {
        return Success(
          AppNotification.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('mark as read failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<int>> markAllAsRead() async {
    try {
      final response = await _apiClient.post('/notifications/read-all');
      if (response.statusCode == 200) {
        return Success(
          (response.data as Map<String, dynamic>)['updated'] as int? ?? 0,
        );
      }
      return const Success(0);
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      final response = await _apiClient.delete(
        '/notifications/$notificationId',
      );
      final code = response.statusCode ?? 0;
      if (code == 204 || code == 200) {
        return const Success(null);
      }
      return loggedFailure(UnknownError('delete notification failed: $code'));
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> registerDeviceToken(
    String fcmToken, {
    String? platform,
    String? locale,
  }) async {
    try {
      await _apiClient.post(
        '/device-tokens',
        data: {
          'fcmToken': fcmToken,
          if (platform != null) 'platform': platform,
          if (locale != null) 'locale': locale,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[BestEffort] registerDeviceToken failed: $e');
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> unregisterDeviceToken(String fcmToken) async {
    try {
      // Token travels in the body — not the URL — so it never lands in
      // server access logs.
      await _apiClient.delete('/device-tokens', data: {'fcmToken': fcmToken});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BestEffort] unregisterDeviceToken failed: $e');
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<NotificationPreferences>> getNotificationPreferences() async {
    try {
      final response = await _apiClient.get('/notifications/preferences');
      if (response.statusCode == 200) {
        return Success(
          NotificationPreferences.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }
      return loggedFailure(
        UnknownError(
          'fetch notification preferences failed: '
          '${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/notifications/preferences',
        data: prefs.toJson(),
      );
      if (response.statusCode == 200) {
        return Success(
          NotificationPreferences.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }
      return loggedFailure(
        UnknownError(
          'update notification preferences failed: '
          '${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
