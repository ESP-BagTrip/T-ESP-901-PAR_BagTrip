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
