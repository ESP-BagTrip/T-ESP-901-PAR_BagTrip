import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/view/step_travelers_budget_view.dart';
import 'package:bagtrip/design/widgets/budget_preset_list.dart';
import 'package:bagtrip/plan_trip/widgets/traveler_breakdown_card.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanTripBloc extends MockBloc<PlanTripEvent, PlanTripState>
    implements PlanTripBloc {}

void main() {
  late MockPlanTripBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const PlanTripEvent.nextStep());
    registerFallbackValue(const PlanTripState());
  });

  setUp(() {
    mockBloc = MockPlanTripBloc();
  });

  Widget buildApp(PlanTripState state) {
    when(() => mockBloc.state).thenReturn(state);
    whenListen(
      mockBloc,
      const Stream<PlanTripState>.empty(),
      initialState: state,
    );

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: BlocProvider<PlanTripBloc>.value(
          value: mockBloc,
          child: const StepTravelersBudgetView(),
        ),
      ),
    );
  }

  group('StepTravelersBudgetView', () {
    testWidgets('renders TravelerBreakdownCard', (tester) async {
      await tester.pumpWidget(buildApp(const PlanTripState()));
      await tester.pumpAndSettle();

      expect(find.byType(TravelerBreakdownCard), findsOneWidget);
    });

    testWidgets('renders budget preset list', (tester) async {
      await tester.pumpWidget(buildApp(const PlanTripState()));
      await tester.pumpAndSettle();

      expect(find.byType(BudgetPresetList), findsOneWidget);
      expect(find.text('Backpacker'), findsOneWidget);
      expect(find.text('Comfortable'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('No limit'), findsOneWidget);
    });

    testWidgets('shows estimation when budget + duration known', (
      tester,
    ) async {
      final state = PlanTripState(
        budgetPreset: BudgetPreset.backpacker,
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 22),
      );
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('ESTIMATED TOTAL'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ESTIMATED TOTAL'), findsOneWidget);
      // 1 traveler * 7 days: 210 – 420 €
      expect(find.text('210 – 420 €'), findsOneWidget);
    });

    testWidgets('hides estimation when no budget', (tester) async {
      final state = PlanTripState(
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 22),
      );
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      expect(find.text('ESTIMATED TOTAL'), findsNothing);
    });

    testWidgets('continue fires nextStep', (tester) async {
      await tester.pumpWidget(buildApp(const PlanTripState()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Continue'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();

      verify(() => mockBloc.add(const PlanTripEvent.nextStep())).called(1);
    });
  });
}
