import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class AiRepositoryImpl implements AiRepository {
  final ApiClient _apiClient;

  AiRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<List<Map<String, dynamic>>>> getInspiration({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
    String? constraints,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/inspire',
        data: {
          if (travelTypes != null) 'travelTypes': travelTypes,
          if (budgetRange != null) 'budgetRange': budgetRange,
          if (durationDays != null) 'durationDays': durationDays,
          if (companions != null) 'companions': companions,
          if (season != null) 'season': season,
          if (constraints != null) 'constraints': constraints,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestions'] is List) {
          return Success(
            (data['suggestions'] as List)
                .map((s) => Map<String, dynamic>.from(s))
                .toList(),
          );
        }
        return const Success([]);
      }
      return Failure(
        UnknownError('get inspiration failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> acceptInspiration(
    Map<String, dynamic> suggestion, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/inspire/accept',
        data: {
          'suggestion': suggestion,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      if (response.statusCode == 200) {
        return Success(Map<String, dynamic>.from(response.data));
      }
      return Failure(
        UnknownError('accept inspiration failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPostTripSuggestion() async {
    try {
      final response = await _apiClient.post('/ai/post-trip-suggestion');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestion'] != null) {
          return Success(Map<String, dynamic>.from(data['suggestion']));
        }
        return Success(Map<String, dynamic>.from(data));
      }
      return Failure(
        UnknownError('get post-trip suggestion failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }
}
