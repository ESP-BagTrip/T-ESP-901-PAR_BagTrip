import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/feedback_service.dart';
import 'package:bagtrip/service/post_trip_ai_service.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';

part 'feedback_event.dart';
part 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc({
    FeedbackService? feedbackService,
    PostTripAiService? postTripAiService,
  }) : _feedbackService = feedbackService ?? getIt<FeedbackService>(),
       _postTripAiService = postTripAiService ?? getIt<PostTripAiService>(),
       super(FeedbackInitial()) {
    on<LoadFeedbacks>(_onLoadFeedbacks);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<RequestPostTripSuggestion>(_onRequestPostTripSuggestion);
  }

  final FeedbackService _feedbackService;
  final PostTripAiService _postTripAiService;

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

  Future<void> _onRequestPostTripSuggestion(
    RequestPostTripSuggestion event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(PostTripSuggestionLoading());
    try {
      final suggestion = await _postTripAiService.getPostTripSuggestion();
      emit(PostTripSuggestionLoaded(suggestion: suggestion));
    } on DioException catch (e) {
      emit(PostTripSuggestionError(message: toUserFriendlyMessage(e)));
    } catch (e) {
      emit(PostTripSuggestionError(message: toUserFriendlyMessage(e)));
    }
  }
}
