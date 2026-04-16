import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/step_status.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/plan_trip/view/step_generation_view.dart';
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
        child: const StepGenerationView(),
      ),
    );
    await tester.pump();
  }

  group('StepGenerationView', () {
    testWidgets('renders default generating state', (tester) async {
      await pump(tester, const PlanTripState());
      expect(find.byType(StepGenerationView), findsOneWidget);
    });

    testWidgets('renders early progress with pending steps', (tester) async {
      await pump(
        tester,
        const PlanTripState(
          generationProgress: 0.2,
          generationMessage: 'Finding destinations...',
          generationSteps: {
            'destinations': StepStatus.inProgress,
            'activities': StepStatus.pending,
            'accommodations': StepStatus.pending,
            'baggage': StepStatus.pending,
            'budget': StepStatus.pending,
          },
        ),
      );
      expect(find.byType(StepGenerationView), findsOneWidget);
    });

    testWidgets('renders mid-progress with mixed statuses', (tester) async {
      await pump(
        tester,
        const PlanTripState(
          generationProgress: 0.6,
          generationMessage: 'Planning activities...',
          generationSteps: {
            'destinations': StepStatus.completed,
            'activities': StepStatus.completed,
            'accommodations': StepStatus.inProgress,
            'baggage': StepStatus.pending,
            'budget': StepStatus.pending,
          },
        ),
      );
      expect(find.byType(StepGenerationView), findsOneWidget);
    });

    testWidgets('renders full-progress with all completed', (tester) async {
      await pump(
        tester,
        const PlanTripState(
          generationProgress: 1.0,
          generationMessage: 'Done',
          generatedPlan: TripPlan(
            destinationCity: 'Lisbon',
            destinationCountry: 'Portugal',
          ),
          generationSteps: {
            'destinations': StepStatus.completed,
            'activities': StepStatus.completed,
            'accommodations': StepStatus.completed,
            'baggage': StepStatus.completed,
            'budget': StepStatus.completed,
          },
        ),
      );
      expect(find.byType(StepGenerationView), findsOneWidget);
    });

    testWidgets('renders error state when generationError is set', (
      tester,
    ) async {
      await pump(
        tester,
        const PlanTripState(generationError: 'Something failed'),
      );
      expect(find.byType(StepGenerationView), findsOneWidget);
    });

    testWidgets('renders with an error status step', (tester) async {
      await pump(
        tester,
        const PlanTripState(
          generationProgress: 0.4,
          generationSteps: {
            'destinations': StepStatus.completed,
            'activities': StepStatus.error,
            'accommodations': StepStatus.pending,
            'baggage': StepStatus.pending,
            'budget': StepStatus.pending,
          },
        ),
      );
      expect(find.byType(StepGenerationView), findsOneWidget);
    });
  });
}
