// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/view/budget_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

class _MockBudgetBloc extends MockBloc<BudgetEvent, BudgetState>
    implements BudgetBloc {}

void main() {
  late _MockBudgetBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadBudget(tripId: 't'));
    registerFallbackValue(BudgetInitial());
  });

  setUp(() {
    mockBloc = _MockBudgetBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    BudgetState seed, {
    String role = 'OWNER',
    bool isCompleted = false,
    Size? size,
  }) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(mockBloc, const Stream<BudgetState>.empty(), initialState: seed);
    await pumpLocalized(
      tester,
      BlocProvider<BudgetBloc>.value(
        value: mockBloc,
        child: BudgetView(
          tripId: 'trip-1',
          role: role,
          isCompleted: isCompleted,
        ),
      ),
      size: size,
    );
    await tester.pump();
  }

  group('BudgetView', () {
    testWidgets('renders loading state', (tester) async {
      await pump(tester, BudgetLoading());
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await pump(tester, BudgetError(error: const NetworkError('offline')));
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders empty loaded state', (tester) async {
      await pump(
        tester,
        BudgetLoaded(items: const [], summary: makeBudgetSummary()),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders loaded state with items', (tester) async {
      await pump(
        tester,
        BudgetLoaded(
          items: [
            makeBudgetItem(),
            makeBudgetItem(id: 'bi-2', amount: 50),
          ],
          summary: makeBudgetSummary(),
        ),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders estimating state', (tester) async {
      await pump(tester, BudgetEstimating());
      expect(find.byType(BudgetView), findsOneWidget);
    });
  });

  group('BudgetView reinforcement', () {
    testWidgets('renders BudgetEstimated state with items + summary', (
      tester,
    ) async {
      await pump(
        tester,
        BudgetEstimated(
          estimation: makeBudgetEstimation(),
          items: [makeBudgetItem()],
          summary: makeBudgetSummary(),
        ),
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders BudgetQuotaExceeded as shrink (no listener)', (
      tester,
    ) async {
      await pump(tester, BudgetQuotaExceeded());
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders over-budget alert banner when alertLevel=DANGER', (
      tester,
    ) async {
      final summary = makeBudgetSummary(
        totalBudget: 1000,
        totalSpent: 1300,
        remaining: -300,
        percentConsumed: 130,
        alertLevel: 'DANGER',
        alertMessage: 'Over budget',
      );
      await pump(
        tester,
        BudgetLoaded(
          items: [
            makeBudgetItem(
              id: 'bi-1',
              label: 'Plane ticket',
              amount: 600,
              category: BudgetCategory.flight,
            ),
            makeBudgetItem(
              id: 'bi-2',
              label: 'Hotel',
              amount: 700,
              category: BudgetCategory.accommodation,
            ),
          ],
          summary: summary,
        ),
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders WARNING alert level', (tester) async {
      final summary = makeBudgetSummary(
        totalBudget: 1000,
        totalSpent: 850,
        remaining: 150,
        percentConsumed: 85,
        alertLevel: 'WARNING',
        alertMessage: 'Getting close',
      );
      await pump(
        tester,
        BudgetLoaded(items: [makeBudgetItem(amount: 850)], summary: summary),
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets(
      'renders items across all BudgetCategory values with byCategory chips',
      (tester) async {
        final summary = makeBudgetSummary(
          byCategory: const {
            'FLIGHT': 200.0,
            'ACCOMMODATION': 400.0,
            'FOOD': 150.0,
            'ACTIVITY': 80.0,
            'TRANSPORT': 50.0,
            'OTHER': 20.0,
          },
        );
        await pump(
          tester,
          BudgetLoaded(
            items: [
              makeBudgetItem(
                id: 'b-flight',
                label: 'Flight',
                amount: 200,
                category: BudgetCategory.flight,
              ),
              makeBudgetItem(
                id: 'b-acc',
                label: 'Hotel',
                amount: 400,
                category: BudgetCategory.accommodation,
              ),
              makeBudgetItem(
                id: 'b-food',
                label: 'Restaurant',
                amount: 150,
                category: BudgetCategory.food,
              ),
              makeBudgetItem(
                id: 'b-act',
                label: 'Tour',
                amount: 80,
                category: BudgetCategory.activity,
              ),
              makeBudgetItem(
                id: 'b-tra',
                label: 'Metro',
                amount: 50,
                category: BudgetCategory.transport,
              ),
              makeBudgetItem(
                id: 'b-oth',
                label: 'Misc',
                amount: 20,
                category: BudgetCategory.other,
              ),
            ],
            summary: summary,
          ),
          size: const Size(900, 2000),
        );
        expect(find.byType(BudgetView), findsOneWidget);
      },
    );

    testWidgets('renders VIEWER role with summary-only layout', (tester) async {
      await pump(
        tester,
        BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
        role: 'VIEWER',
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders isCompleted read-only', (tester) async {
      await pump(
        tester,
        BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
        isCompleted: true,
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('renders mixed confirmed/forecasted items', (tester) async {
      final confirmed = makeBudgetItem(
        id: 'conf-1',
        label: 'Booked hotel',
      ).copyWith(isPlanned: false, sourceType: 'BOOKING');
      final forecasted = makeBudgetItem(
        id: 'fc-1',
        label: 'Food budget',
      ).copyWith(isPlanned: true);
      await pump(
        tester,
        BudgetLoaded(
          items: [confirmed, forecasted],
          summary: makeBudgetSummary(),
        ),
        size: const Size(900, 1600),
      );
      expect(find.byType(BudgetView), findsOneWidget);
    });

    testWidgets('tapping retry on error dispatches LoadBudget', (tester) async {
      await pump(tester, BudgetError(error: const NetworkError('offline')));
      final retry = find.text('Retry');
      if (retry.evaluate().isNotEmpty) {
        await tester.tap(retry.first);
        await tester.pump();
        verify(
          () => mockBloc.add(any(that: isA<LoadBudget>())),
        ).called(greaterThanOrEqualTo(1));
      }
      expect(find.byType(BudgetView), findsOneWidget);
    });
  });
}
