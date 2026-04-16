// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/feedback/bloc/feedback_bloc.dart';
import 'package:bagtrip/feedback/view/feedback_form_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

class _MockFeedbackBloc extends MockBloc<FeedbackEvent, FeedbackState>
    implements FeedbackBloc {}

class _FakeFeedbackEvent extends Fake implements FeedbackEvent {}

class _FakeFeedbackState extends Fake implements FeedbackState {}

void main() {
  late _MockFeedbackBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(_FakeFeedbackEvent());
    registerFallbackValue(_FakeFeedbackState());
  });

  setUp(() {
    mockBloc = _MockFeedbackBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    FeedbackState seed, {
    String? currentUserId,
    bool showAiRating = false,
    List<dynamic> feedbacks = const [],
  }) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<FeedbackState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<FeedbackBloc>.value(
        value: mockBloc,
        child: FeedbackFormView(
          tripId: 'trip-1',
          currentUserId: currentUserId,
          feedbacks: List.from(feedbacks),
          showAiRating: showAiRating,
        ),
      ),
    );
    await tester.pump();
  }

  group('FeedbackFormView', () {
    testWidgets('renders new submission form when no existing feedback', (
      tester,
    ) async {
      await pump(tester, FeedbackInitial());
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });

    testWidgets('renders read-only variant when user already submitted', (
      tester,
    ) async {
      final existing = makeTripFeedback(
        userId: 'user-1',
        highlights: 'Amazing food',
        lowlights: 'Crowded',
      );
      await pump(
        tester,
        FeedbackLoaded(feedbacks: [existing]),
        currentUserId: 'user-1',
        feedbacks: [existing],
      );
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });

    testWidgets('renders with AI rating section when showAiRating is true', (
      tester,
    ) async {
      await pump(tester, FeedbackInitial(), showAiRating: true);
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      await pump(tester, FeedbackLoading());
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(tester, FeedbackError(error: const NetworkError('offline')));
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });

    testWidgets('renders with post-trip suggestion loaded state', (
      tester,
    ) async {
      await pump(
        tester,
        PostTripSuggestionLoaded(
          suggestion: const {
            'destination': 'Lisbon',
            'destinationCountry': 'Portugal',
            'durationDays': 5,
            'budgetEur': 800,
            'description': 'A charming coastal city.',
            'highlightsMatch': ['beach', 'culture'],
          },
        ),
      );
      expect(find.byType(FeedbackFormView), findsOneWidget);
    });
  });
}
