import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc({
    FeedbackRepository? feedbackRepository,
    AiRepository? aiRepository,
  }) : _feedbackRepository = feedbackRepository ?? getIt<FeedbackRepository>(),
       _aiRepository = aiRepository ?? getIt<AiRepository>(),
       super(FeedbackInitial()) {
    on<LoadFeedbacks>(_onLoadFeedbacks);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<RequestPostTripSuggestion>(_onRequestPostTripSuggestion);
  }

  final FeedbackRepository _feedbackRepository;
  final AiRepository _aiRepository;

  Future<void> _onLoadFeedbacks(
    LoadFeedbacks event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    final result = await _feedbackRepository.getFeedbacks(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(FeedbackLoaded(feedbacks: data));
      case Failure(:final error):
        emit(FeedbackError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    final result = await _feedbackRepository.submitFeedback(
      event.tripId,
      overallRating: event.overallRating,
      highlights: event.highlights,
      lowlights: event.lowlights,
      wouldRecommend: event.wouldRecommend,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(FeedbackSubmitted());
        add(LoadFeedbacks(tripId: event.tripId));
      case Failure(:final error):
        emit(FeedbackError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onRequestPostTripSuggestion(
    RequestPostTripSuggestion event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(PostTripSuggestionLoading());
    final result = await _aiRepository.getPostTripSuggestion();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(PostTripSuggestionLoaded(suggestion: data));
      case Failure(:final error):
        emit(PostTripSuggestionError(message: toUserFriendlyMessage(error)));
    }
  }
}
