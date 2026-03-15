import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<String>> getCheckoutUrl() async {
    try {
      final response = await _apiClient.post('/subscription/checkout');
      return Success(response.data['url'] as String);
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
      return Success(response.data['url'] as String);
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
      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
