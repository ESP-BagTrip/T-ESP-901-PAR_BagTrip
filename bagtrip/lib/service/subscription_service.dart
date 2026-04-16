import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<Result<String>> getCheckoutUrl() async {
    try {
      final response = await _apiClient.post('/subscription/checkout');
      final data = response.data;
      if (data is Map && data['url'] is String) {
        return Success(data['url'] as String);
      }
      return loggedFailure(
        const ServerError('Invalid checkout response: missing url'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<String>> getPortalUrl() async {
    try {
      final response = await _apiClient.post('/subscription/portal');
      final data = response.data;
      if (data is Map && data['url'] is String) {
        return Success(data['url'] as String);
      }
      return loggedFailure(
        const ServerError('Invalid portal response: missing url'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getStatus() async {
    try {
      final response = await _apiClient.get('/subscription/status');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Success(data);
      }
      return loggedFailure(const ServerError('Invalid status response format'));
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
