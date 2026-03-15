import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/budget_estimation.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final ApiClient _apiClient;

  BudgetRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<List<BudgetItem>>> getBudgetItems(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/budget-items');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(
            data.map((json) => BudgetItem.fromJson(json)).toList(),
          );
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => BudgetItem.fromJson(json))
                .toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch budget items failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<BudgetSummary>> getBudgetSummary(String tripId) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/budget-items/summary',
      );
      if (response.statusCode == 200) {
        return Success(
          BudgetSummary.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('fetch budget summary failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<BudgetItem>> createBudgetItem(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/budget-items',
        data: data,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(BudgetItem.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<BudgetItem>> updateBudgetItem(
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/budget-items/$itemId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Success(BudgetItem.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteBudgetItem(String tripId, String itemId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/budget-items/$itemId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<BudgetEstimation>> estimateBudget(String tripId) async {
    try {
      final response = await _apiClient.post('/trips/$tripId/budget/estimate');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['estimation'] is Map) {
          return Success(
            BudgetEstimation.fromJson(
              Map<String, dynamic>.from(data['estimation']),
            ),
          );
        }
        return loggedFailure(const UnknownError('Invalid estimation response'));
      }
      return loggedFailure(
        UnknownError('estimate budget failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> acceptBudgetEstimate(
    String tripId,
    double budgetTotal,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/budget/estimate/accept',
        data: {'budget_total': budgetTotal},
      );
      if (response.statusCode == 200) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('accept budget estimate failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
