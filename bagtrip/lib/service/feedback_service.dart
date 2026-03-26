import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final ApiClient _apiClient;

  FeedbackRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<TripFeedback>> submitFeedback(
    String tripId, {
    required int overallRating,
    String? highlights,
    String? lowlights,
    required bool wouldRecommend,
    int? aiExperienceRating,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/feedback',
        data: {
          'overallRating': overallRating,
          if (highlights != null) 'highlights': highlights,
          if (lowlights != null) 'lowlights': lowlights,
          'wouldRecommend': wouldRecommend,
          if (aiExperienceRating != null)
            'aiExperienceRating': aiExperienceRating,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(TripFeedback.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('submit feedback failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<TripFeedback>>> getFeedbacks(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/feedback');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => TripFeedback.fromJson(json))
                .toList(),
          );
        }
        if (data is List) {
          return Success(
            data.map((json) => TripFeedback.fromJson(json)).toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch feedbacks failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
