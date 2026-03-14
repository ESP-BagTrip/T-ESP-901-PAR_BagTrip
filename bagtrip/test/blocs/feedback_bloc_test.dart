import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockFeedbackRepository mockFeedbackRepo;
  late MockAiRepository mockAiRepo;

  setUp(() {
    mockFeedbackRepo = MockFeedbackRepository();
    mockAiRepo = MockAiRepository();
  });

  group('FeedbackBloc', () {
    // ── LoadFeedbacks ───────────────────────────────────────────────────

    blocTest<FeedbackBloc, FeedbackState>(
      'emits [FeedbackLoading, FeedbackLoaded] when LoadFeedbacks succeeds',
      build: () {
        when(
          () => mockFeedbackRepo.getFeedbacks(any()),
        ).thenAnswer((_) async => Success([makeTripFeedback()]));
        return FeedbackBloc(
          feedbackRepository: mockFeedbackRepo,
          aiRepository: mockAiRepo,
        );
      },
      act: (bloc) => bloc.add(LoadFeedbacks(tripId: 'trip-1')),
      expect: () => [isA<FeedbackLoading>(), isA<FeedbackLoaded>()],
      verify: (bloc) {
        final state = bloc.state as FeedbackLoaded;
        expect(state.feedbacks.length, 1);
        expect(state.feedbacks.first.overallRating, 4);
        verify(() => mockFeedbackRepo.getFeedbacks('trip-1')).called(1);
      },
    );

    blocTest<FeedbackBloc, FeedbackState>(
      'emits [FeedbackLoading, FeedbackError] when LoadFeedbacks fails',
      build: () {
        when(
          () => mockFeedbackRepo.getFeedbacks(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return FeedbackBloc(
          feedbackRepository: mockFeedbackRepo,
          aiRepository: mockAiRepo,
        );
      },
      act: (bloc) => bloc.add(LoadFeedbacks(tripId: 'trip-1')),
      expect: () => [isA<FeedbackLoading>(), isA<FeedbackError>()],
    );

    // ── SubmitFeedback ──────────────────────────────────────────────────

    blocTest<FeedbackBloc, FeedbackState>(
      'emits [FeedbackLoading, FeedbackSubmitted, ...] then triggers LoadFeedbacks on success',
      build: () {
        when(
          () => mockFeedbackRepo.submitFeedback(
            any(),
            overallRating: any(named: 'overallRating'),
            highlights: any(named: 'highlights'),
            lowlights: any(named: 'lowlights'),
            wouldRecommend: any(named: 'wouldRecommend'),
          ),
        ).thenAnswer((_) async => Success(makeTripFeedback()));
        when(
          () => mockFeedbackRepo.getFeedbacks(any()),
        ).thenAnswer((_) async => Success([makeTripFeedback()]));
        return FeedbackBloc(
          feedbackRepository: mockFeedbackRepo,
          aiRepository: mockAiRepo,
        );
      },
      act: (bloc) => bloc.add(
        SubmitFeedback(tripId: 'trip-1', overallRating: 4, highlights: 'Great'),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<FeedbackLoading>(),
        isA<FeedbackSubmitted>(),
        // LoadFeedbacks is triggered internally
        isA<FeedbackLoading>(),
        isA<FeedbackLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockFeedbackRepo.submitFeedback(
            'trip-1',
            overallRating: 4,
            highlights: 'Great',
            wouldRecommend: true,
          ),
        ).called(1);
        verify(() => mockFeedbackRepo.getFeedbacks('trip-1')).called(1);
      },
    );

    // ── RequestPostTripSuggestion ───────────────────────────────────────

    blocTest<FeedbackBloc, FeedbackState>(
      'emits [PostTripSuggestionLoading, PostTripSuggestionLoaded] on success',
      build: () {
        when(() => mockAiRepo.getPostTripSuggestion()).thenAnswer(
          (_) async => const Success(<String, dynamic>{
            'suggestion': 'Try visiting Japan next!',
          }),
        );
        return FeedbackBloc(
          feedbackRepository: mockFeedbackRepo,
          aiRepository: mockAiRepo,
        );
      },
      act: (bloc) => bloc.add(RequestPostTripSuggestion()),
      expect: () => [
        isA<PostTripSuggestionLoading>(),
        isA<PostTripSuggestionLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as PostTripSuggestionLoaded;
        expect(state.suggestion['suggestion'], 'Try visiting Japan next!');
      },
    );

    blocTest<FeedbackBloc, FeedbackState>(
      'emits [PostTripSuggestionLoading, PostTripSuggestionError] on failure',
      build: () {
        when(
          () => mockAiRepo.getPostTripSuggestion(),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return FeedbackBloc(
          feedbackRepository: mockFeedbackRepo,
          aiRepository: mockAiRepo,
        );
      },
      act: (bloc) => bloc.add(RequestPostTripSuggestion()),
      expect: () => [
        isA<PostTripSuggestionLoading>(),
        isA<PostTripSuggestionError>(),
      ],
    );
  });
}
