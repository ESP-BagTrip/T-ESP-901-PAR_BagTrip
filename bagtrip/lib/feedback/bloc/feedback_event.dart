part of 'feedback_bloc.dart';

abstract class FeedbackEvent {}

class LoadFeedbacks extends FeedbackEvent {
  final String tripId;
  LoadFeedbacks({required this.tripId});
}

class SubmitFeedback extends FeedbackEvent {
  final String tripId;
  final int overallRating;
  final String? highlights;
  final String? lowlights;
  final bool wouldRecommend;

  SubmitFeedback({
    required this.tripId,
    required this.overallRating,
    this.highlights,
    this.lowlights,
    required this.wouldRecommend,
  });
}
