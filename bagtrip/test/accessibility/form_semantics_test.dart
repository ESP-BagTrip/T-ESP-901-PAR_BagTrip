// ignore_for_file: avoid_redundant_argument_values
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/view/step_destination_view.dart';
import 'package:bagtrip/plan_trip/view/step_travelers_budget_view.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';

class _MockPlanTripBloc extends MockBloc<PlanTripEvent, PlanTripState>
    implements PlanTripBloc {}

/// Finds the explicit [Semantics] widget that flags [textField] with the
/// given [label]. Used to assert SMP327-042 form-field announcements.
Finder _textFieldSemantics(String label) {
  return find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        (w.properties.textField ?? false) &&
        w.properties.label == label,
  );
}

void main() {
  late _MockPlanTripBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(const PlanTripEvent.nextStep());
    registerFallbackValue(const PlanTripState());
  });

  setUp(() {
    mockBloc = _MockPlanTripBloc();
  });

  Future<void> pumpView(WidgetTester tester, Widget view) async {
    when(() => mockBloc.state).thenReturn(const PlanTripState());
    whenListen(
      mockBloc,
      const Stream<PlanTripState>.empty(),
      initialState: const PlanTripState(),
    );
    await pumpLocalized(
      tester,
      BlocProvider<PlanTripBloc>.value(value: mockBloc, child: view),
    );
    await tester.pump();
  }

  group('AX1 — Form field semantics (SMP327-042)', () {
    testWidgets('destination search field exposes a labelled textField', (
      tester,
    ) async {
      await pumpView(tester, const StepDestinationView());
      // "DESTINATION" = l10n.destinationSectionLabel (en).
      expect(_textFieldSemantics('DESTINATION'), findsOneWidget);
    });

    testWidgets('origin city field exposes a labelled textField', (
      tester,
    ) async {
      await pumpView(tester, const StepTravelersBudgetView());
      // "DEPARTING FROM" = l10n.originCityLabel (en).
      expect(_textFieldSemantics('DEPARTING FROM'), findsOneWidget);
    });
  });
}
