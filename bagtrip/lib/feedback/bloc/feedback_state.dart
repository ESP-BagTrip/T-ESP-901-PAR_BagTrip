part of 'feedback_bloc.dart';

abstract class FeedbackState {}

class FeedbackInitial extends FeedbackState {}

class FeedbackLoading extends FeedbackState {}

class FeedbackLoaded extends FeedbackState {
  final List<TripFeedback> feedbacks;
  FeedbackLoaded({required this.feedbacks});
}

class FeedbackSubmitted extends FeedbackState {}

class FeedbackError extends FeedbackState {
  final AppError error;
  FeedbackError({required this.error});
}

class PostTripSuggestionLoading extends FeedbackState {}

class PostTripSuggestionLoaded extends FeedbackState {
  final Map<String, dynamic> suggestion;
  PostTripSuggestionLoaded({required this.suggestion});
}

class PostTripSuggestionError extends FeedbackState {
  final AppError error;
  PostTripSuggestionError({required this.error});
}
