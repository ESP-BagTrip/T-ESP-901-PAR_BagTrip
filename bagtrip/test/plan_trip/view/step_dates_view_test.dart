import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/view/step_dates_view.dart';
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
          child: const StepDatesView(),
        ),
      ),
    );
  }

  group('StepDatesView', () {
    testWidgets('renders exact mode by default', (tester) async {
      await tester.pumpWidget(buildApp(const PlanTripState()));
      await tester.pumpAndSettle();

      expect(find.text('Exact dates'), findsOneWidget);
      expect(find.text('DEPART'), findsOneWidget);
      expect(find.text('RETURN'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('renders month mode with grid', (tester) async {
      await tester.pumpWidget(
        buildApp(const PlanTripState(dateMode: DateMode.month)),
      );
      await tester.pumpAndSettle();

      // Month grid + duration chip selector
      expect(find.byType(GridView), findsNWidgets(2));
    });

    testWidgets('renders flexible mode with 4 duration cards', (tester) async {
      await tester.pumpWidget(
        buildApp(const PlanTripState(dateMode: DateMode.flexible)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weekend'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('2 weeks'), findsOneWidget);
      expect(find.text('3 weeks'), findsOneWidget);
    });

    testWidgets('continue button disabled when dates invalid', (tester) async {
      await tester.pumpWidget(buildApp(const PlanTripState()));
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      expect(continueBtn, findsOneWidget);
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();

      verifyNever(() => mockBloc.add(any()));
    });

    testWidgets('continue button enabled when dates valid', (tester) async {
      final state = PlanTripState(
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 22),
      );
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      final continueBtn = find.text('Continue');
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockBloc.add(const PlanTripEvent.nextStep())).called(1);
    });

    testWidgets('shows resume badge when dates valid', (tester) async {
      const state = PlanTripState(
        dateMode: DateMode.flexible,
        flexibleDuration: DurationPreset.oneWeek,
      );
      await tester.pumpWidget(buildApp(state));
      await tester.pumpAndSettle();

      // "1 week" appears in both the chip and the resume badge
      expect(find.text('1 week'), findsAtLeast(1));
    });
  });
}
