import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/view/step_ai_proposals_view.dart';
import 'package:bloc_test/bloc_test.dart';
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

  group('StepAiProposalsView', () {
    testWidgets('renders elegant empty state when aiSuggestions is empty', (
      tester,
    ) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepAiProposalsView), findsOneWidget);
    });

    testWidgets('renders carousel with single AI suggestion', (tester) async {
      await pump(tester, const PlanTripState(aiSuggestions: [lisbon]));
      expect(find.byType(StepAiProposalsView), findsOneWidget);
    });

    testWidgets('renders carousel with multiple AI suggestions', (
      tester,
    ) async {
      await pump(
        tester,
        const PlanTripState(aiSuggestions: [lisbon, barcelona, tokyo]),
      );
      expect(find.byType(StepAiProposalsView), findsOneWidget);
    });
  });
}
