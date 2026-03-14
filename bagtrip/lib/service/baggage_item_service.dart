import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class BaggageRepositoryImpl implements BaggageRepository {
  final ApiClient _apiClient;

  BaggageRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<BaggageItem>> createBaggageItem(
    String tripId, {
    required String name,
    int? quantity,
    bool? isPacked,
    String? category,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/baggage',
        data: {
          'name': name,
          if (quantity != null) 'quantity': quantity,
          if (isPacked != null) 'isPacked': isPacked,
          if (category != null) 'category': category,
          if (notes != null) 'notes': notes,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(BaggageItem.fromJson(response.data));
      }
      return Failure(
        UnknownError('create baggage item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<BaggageItem>>> getByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/baggage');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(
            data.map((json) => BaggageItem.fromJson(json)).toList(),
          );
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => BaggageItem.fromJson(json))
                .toList(),
          );
        }
        return const Success([]);
      }
      return Failure(
        UnknownError('fetch baggage items failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<BaggageItem>> updateBaggageItem(
    String tripId,
    String baggageItemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/baggage/$baggageItemId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Success(BaggageItem.fromJson(response.data));
      }
      return Failure(
        UnknownError('update baggage item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteBaggageItem(
    String tripId,
    String baggageItemId,
  ) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/baggage/$baggageItemId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return Failure(
        UnknownError('delete baggage item failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> suggestBaggage(
    String tripId,
  ) async {
    try {
      final response = await _apiClient.post('/trips/$tripId/baggage/suggest');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList(),
          );
        }
        return const Success([]);
      }
      return Failure(
        UnknownError('suggest baggage failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }
}
