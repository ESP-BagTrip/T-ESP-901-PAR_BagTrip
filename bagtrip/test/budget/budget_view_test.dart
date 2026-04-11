import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/budget/view/budget_view.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bloc_test/bloc_test.dart';
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

  Future<void> pump(WidgetTester tester, BudgetState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(mockBloc, const Stream<BudgetState>.empty(), initialState: seed);
    await pumpLocalized(
      tester,
      BlocProvider<BudgetBloc>.value(
        value: mockBloc,
        child: const BudgetView(tripId: 'trip-1'),
      ),
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
}
