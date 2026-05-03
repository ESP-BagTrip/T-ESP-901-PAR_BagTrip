import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/view/step_ai_proposals_view.dart';
import 'package:bagtrip/plan_trip/widgets/ai_destination_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockPlanTripBloc extends MockBloc<PlanTripEvent, PlanTripState>
    implements PlanTripBloc {}

void main() {
  late _MockPlanTripBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const PlanTripEvent.nextStep());
    registerFallbackValue(const PlanTripState());
  });

  setUp(() {
    mockBloc = _MockPlanTripBloc();
  });

  Future<void> pump(WidgetTester tester, PlanTripState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<PlanTripState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      BlocProvider<PlanTripBloc>.value(
        value: mockBloc,
        child: const StepAiProposalsView(),
      ),
    );
    await tester.pump();
  }

  // imageUrl is intentionally null so the card uses its local placeholder
  // and no network image is fetched in tests.
  const lisbon = AiDestination(
    city: 'Lisbon',
    country: 'Portugal',
    matchReason: 'Mediterranean charm',
    weatherSummary: 'Sunny 22C',
    topActivities: ['Tram ride', 'Belem tower'],
  );
  const barcelona = AiDestination(
    city: 'Barcelona',
    country: 'Spain',
    matchReason: 'Art and beach',
    topActivities: ['Sagrada', 'Beach'],
  );
  const tokyo = AiDestination(
    city: 'Tokyo',
    country: 'Japan',
    topActivities: ['Shibuya', 'Asakusa'],
  );
  const oslo = AiDestination(
    city: 'Oslo',
    country: 'Norway',
    matchReason: 'Secure city, great transport and rich culture.',
  );

  group('StepAiProposalsView', () {
    testWidgets('renders elegant empty state when aiSuggestions is empty', (
      tester,
    ) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepAiProposalsView), findsOneWidget);
    });

    testWidgets('renders list with single AI suggestion', (tester) async {
      await pump(tester, const PlanTripState(aiSuggestions: [lisbon]));
      expect(find.byType(StepAiProposalsView), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(AiDestinationCard), findsOneWidget);
    });

    testWidgets('renders list with multiple AI suggestions', (tester) async {
      await pump(
        tester,
        const PlanTripState(aiSuggestions: [lisbon, barcelona, tokyo]),
      );
      expect(find.byType(StepAiProposalsView), findsOneWidget);
      expect(find.byType(AiDestinationCard), findsWidgets);
      expect(find.text('Sunny 22C'), findsOneWidget);
    });

    testWidgets('tapping a card dispatches swipeProposal with card index', (
      tester,
    ) async {
      await pump(
        tester,
        const PlanTripState(aiSuggestions: [lisbon, barcelona, tokyo]),
      );

      await tester.tap(find.byType(AiDestinationCard).first);
      await tester.pumpAndSettle();

      verify(
        () => mockBloc.add(const PlanTripEvent.swipeProposal(0)),
      ).called(1);
    });

    testWidgets(
      'shows match reason but no chips when AI omits weather and activities',
      (tester) async {
        await pump(tester, const PlanTripState(aiSuggestions: [oslo]));

        // Match reason renders as before.
        expect(
          find.text('Secure city, great transport and rich culture.'),
          findsOneWidget,
        );

        // Without weather/activities the previous mock fallbacks are gone;
        // no FR Lisbon stubs leak through.
        expect(find.text('18–22°C au printemps'), findsNothing);
        expect(find.text('Alfama & Sao Jorge'), findsNothing);
        expect(find.text('Pastel de nata'), findsNothing);
      },
    );

    testWidgets('show more / show less toggle is hidden when activities <= 3', (
      tester,
    ) async {
      await pump(tester, const PlanTripState(aiSuggestions: [lisbon]));
      // Lisbon has only 2 activities — toggle stays hidden.
      expect(find.text('Show more'), findsNothing);
      expect(find.text('Show less'), findsNothing);
    });

    testWidgets(
      'show more reveals additional activities on tap and toggles to show less',
      (tester) async {
        const longList = AiDestination(
          city: 'Madrid',
          country: 'Spain',
          topActivities: ['Prado', 'Retiro', 'Tapas', 'Flamenco', 'Sol'],
        );
        await pump(tester, const PlanTripState(aiSuggestions: [longList]));

        // Initially only the first 3 activities are visible.
        expect(find.text('Prado'), findsOneWidget);
        expect(find.text('Retiro'), findsOneWidget);
        expect(find.text('Tapas'), findsOneWidget);
        expect(find.text('Flamenco'), findsNothing);
        expect(find.text('Show more'), findsOneWidget);

        await tester.tap(find.text('Show more'));
        await tester.pump();

        expect(find.text('Flamenco'), findsOneWidget);
        expect(find.text('Sol'), findsOneWidget);
        expect(find.text('Show less'), findsOneWidget);
      },
    );
  });
}
