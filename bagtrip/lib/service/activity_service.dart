import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<List<Activity>>> getActivities(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/activities');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(data.map((json) => Activity.fromJson(json)).toList());
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => Activity.fromJson(json))
                .toList(),
          );
        }
        return const Failure(ServerError('Invalid response format'));
      }
      return loggedFailure(
        UnknownError('fetch activities failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<PaginatedResponse<Activity>>> getActivitiesPaginated(
    String tripId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/activities',
        queryParameters: {'page': page, 'limit': limit},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map((json) => Activity.fromJson(json))
            .toList();
        return Success(
          PaginatedResponse<Activity>(
            items: items,
            total: data['total'] as int,
            page: data['page'] as int,
            totalPages: (data['totalPages'] ?? data['total_pages']) as int,
          ),
        );
      }
      return loggedFailure(
        UnknownError(
          'fetch activities paginated failed: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Activity>> createActivity(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/activities',
        data: data,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(Activity.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create activity failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Activity>> updateActivity(
    String tripId,
    String activityId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/activities/$activityId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Success(Activity.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update activity failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteActivity(String tripId, String activityId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/activities/$activityId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete activity failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> suggestActivities(
    String tripId,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/activities/suggest',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['activities'] is List) {
          return Success(
            (data['activities'] as List)
                .map((a) => Map<String, dynamic>.from(a))
                .toList(),
          );
        }
        return const Failure(ServerError('Invalid suggestion response format'));
      }
      return loggedFailure(
        UnknownError('suggest activities failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
