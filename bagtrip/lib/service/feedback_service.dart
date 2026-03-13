import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/service/api_client.dart';

class FeedbackService {
  final ApiClient _apiClient;

  FeedbackService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Submit feedback for a completed trip.
  Future<TripFeedback> submitFeedback(
    String tripId, {
    required int overallRating,
    String? highlights,
    String? lowlights,
    required bool wouldRecommend,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/feedback',
        data: {
          'overallRating': overallRating,
          if (highlights != null) 'highlights': highlights,
          if (lowlights != null) 'lowlights': lowlights,
          'wouldRecommend': wouldRecommend,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TripFeedback.fromJson(response.data);
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting feedback: $e');
    }
  }

  /// Get all feedbacks for a trip.
  Future<List<TripFeedback>> getFeedbacks(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/feedback');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => TripFeedback.fromJson(json))
              .toList();
        }
        if (data is List) {
          return data.map((json) => TripFeedback.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch feedbacks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching feedbacks: $e');
    }
  }
}
