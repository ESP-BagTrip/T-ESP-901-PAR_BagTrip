import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map(
              (json) => AppNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Success({
          'items': items,
          'total': data['total'] ?? 0,
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'totalPages': data['totalPages'] ?? data['total_pages'] ?? 0,
          'unreadCount': data['unreadCount'] ?? data['unread_count'] ?? 0,
        });
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
      debugPrint('[BestEffort] getUnreadCount failed: $e');
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
  Future<Result<void>> registerDeviceToken(
    String fcmToken, {
    String? platform,
  }) async {
    try {
      await _apiClient.post(
        '/device-tokens',
        data: {
          'fcmToken': fcmToken,
          if (platform != null) 'platform': platform,
        },
      );
    } catch (e) {
      debugPrint('[BestEffort] registerDeviceToken failed: $e');
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> unregisterDeviceToken(String fcmToken) async {
    try {
      await _apiClient.delete('/device-tokens/$fcmToken');
    } catch (e) {
      debugPrint('[BestEffort] unregisterDeviceToken failed: $e');
    }
    return const Success(null);
  }
}
