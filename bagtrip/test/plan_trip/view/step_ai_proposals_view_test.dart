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

    testWidgets('keeps description and shows mock chips when data is missing', (
      tester,
    ) async {
      await pump(tester, const PlanTripState(aiSuggestions: [oslo]));

      expect(
        find.text('Secure city, great transport and rich culture.'),
        findsOneWidget,
      );
      expect(find.text('18–22°C au printemps'), findsOneWidget);
      expect(find.text('Alfama & Sao Jorge'), findsOneWidget);
    });
  });
}
