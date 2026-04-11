import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/widgets/budget_estimate_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
import '../../helpers/test_fixtures.dart';

class _MockBudgetBloc extends MockBloc<BudgetEvent, BudgetState>
    implements BudgetBloc {}

void main() {
  late _MockBudgetBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadBudget(tripId: 't'));
    registerFallbackValue(AcceptBudgetEstimate(tripId: 't', budgetTotal: 0));
    registerFallbackValue(BudgetInitial());
  });

  setUp(() {
    mockBloc = _MockBudgetBloc();
  });

  Future<void> pump(WidgetTester tester, BudgetState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(mockBloc, const Stream<BudgetState>.empty(), initialState: seed);
    await pumpLocalized(
      tester,
      BlocProvider<BudgetBloc>.value(
        value: mockBloc,
        child: const SizedBox(
          width: 800,
          height: 1200,
          child: BudgetEstimateSheet(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pump();
  }

  group('BudgetEstimateSheet', () {
    testWidgets('renders in initial state', (tester) async {
      await pump(tester, BudgetInitial());
      expect(find.byType(BudgetEstimateSheet), findsOneWidget);
    });

    testWidgets('renders estimating shimmer state', (tester) async {
      await pump(tester, BudgetEstimating());
      expect(find.byType(BudgetEstimateSheet), findsOneWidget);
    });

    testWidgets('renders estimated state with full breakdown', (tester) async {
      await pump(
        tester,
        BudgetEstimated(
          estimation: makeBudgetEstimation(),
          items: const [],
          summary: makeBudgetSummary(),
        ),
      );
      expect(find.byType(BudgetEstimateSheet), findsOneWidget);
    });

    testWidgets('renders estimated state with breakdown notes', (tester) async {
      await pump(
        tester,
        BudgetEstimated(
          estimation: makeBudgetEstimation(
            breakdownNotes: 'Note about this estimation',
          ),
          items: const [],
          summary: makeBudgetSummary(),
        ),
      );
      expect(find.byType(BudgetEstimateSheet), findsOneWidget);
    });
  });
}
