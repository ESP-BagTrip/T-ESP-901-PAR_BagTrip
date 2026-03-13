import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/service/feedback_service.dart';
import 'package:bloc/bloc.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc({FeedbackService? feedbackService})
    : _feedbackService = feedbackService ?? FeedbackService(),
      super(FeedbackInitial()) {
    on<LoadFeedbacks>(_onLoadFeedbacks);
    on<SubmitFeedback>(_onSubmitFeedback);
  }

  final FeedbackService _feedbackService;

  Future<void> _onLoadFeedbacks(
    LoadFeedbacks event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    try {
      final feedbacks = await _feedbackService.getFeedbacks(event.tripId);
      emit(FeedbackLoaded(feedbacks: feedbacks));
    } catch (e) {
      emit(FeedbackError(message: e.toString()));
    }
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    try {
      await _feedbackService.submitFeedback(
        event.tripId,
        overallRating: event.overallRating,
        highlights: event.highlights,
        lowlights: event.lowlights,
        wouldRecommend: event.wouldRecommend,
      );
      emit(FeedbackSubmitted());
      add(LoadFeedbacks(tripId: event.tripId));
    } catch (e) {
      emit(FeedbackError(message: e.toString()));
    }
  }
}
