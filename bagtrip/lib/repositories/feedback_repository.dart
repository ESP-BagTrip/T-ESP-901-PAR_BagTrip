import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/feedback.dart';

abstract class FeedbackRepository {
  Future<Result<TripFeedback>> submitFeedback(
    String tripId, {
    required int overallRating,
    String? highlights,
    String? lowlights,
    required bool wouldRecommend,
  });
  Future<Result<List<TripFeedback>>> getFeedbacks(String tripId);
}
