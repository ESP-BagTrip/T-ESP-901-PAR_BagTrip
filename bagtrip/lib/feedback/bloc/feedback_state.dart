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
  final String message;
  FeedbackError({required this.message});
}

class PostTripSuggestionLoading extends FeedbackState {}

class PostTripSuggestionLoaded extends FeedbackState {
  final Map<String, dynamic> suggestion;
  PostTripSuggestionLoaded({required this.suggestion});
}

class PostTripSuggestionError extends FeedbackState {
  final String message;
  PostTripSuggestionError({required this.message});
}
