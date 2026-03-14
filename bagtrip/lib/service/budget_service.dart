import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
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
      return Failure(
        UnknownError('fetch budget items failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
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
      return Failure(
        UnknownError('fetch budget summary failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
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
      return Failure(
        UnknownError('create budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
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
      return Failure(
        UnknownError('update budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
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
      return Failure(
        UnknownError('delete budget item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }
}
