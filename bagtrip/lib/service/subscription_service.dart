import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/invoice.dart';
import 'package:bagtrip/models/subscription_details.dart';
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

  @override
  Future<Result<SubscriptionDetails>> getDetails() async {
    try {
      final response = await _apiClient.get('/subscription/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Success(SubscriptionDetails.fromJson(data));
      }
      return loggedFailure(
        const ServerError('Invalid subscription details response'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> cancel() async {
    try {
      final response = await _apiClient.post('/subscription/cancel');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        ServerError('cancel failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> reactivate() async {
    try {
      final response = await _apiClient.post('/subscription/reactivate');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        ServerError('reactivate failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Invoice>>> listInvoices({int limit = 12}) async {
    try {
      final response = await _apiClient.get(
        '/subscription/invoices',
        queryParameters: {'limit': limit},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['invoices'] as List<dynamic>? ?? [];
        return Success(
          list.map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
      return loggedFailure(const ServerError('Invalid invoices response'));
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
