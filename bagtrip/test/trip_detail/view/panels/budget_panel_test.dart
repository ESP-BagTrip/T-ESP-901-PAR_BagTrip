// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/trip_detail/view/panels/budget_panel.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_fixtures.dart';

class _MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

BudgetItem _expense({
  String id = 'exp-1',
  String label = 'Coffee',
  double amount = 4.5,
  BudgetCategory category = BudgetCategory.food,
  DateTime? date,
  bool isPlanned = false,
}) {
  return BudgetItem(
    id: id,
    tripId: 'trip-1',
    label: label,
    amount: amount,
    category: category,
    date: date ?? DateTime(2026, 4, 10),
    isPlanned: isPlanned,
  );
}

void main() {
  late _MockTripDetailBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      CreateBudgetItemFromDetail(data: <String, dynamic>{}),
    );
    registerFallbackValue(
      UpdateBudgetItemFromDetail(itemId: 'x', data: <String, dynamic>{}),
    );
    registerFallbackValue(DeleteBudgetItemFromDetail(itemId: 'x'));
  });

  setUp(() {
    bloc = _MockTripDetailBloc();
    when(() => bloc.state).thenReturn(
      TripDetailLoaded(
        trip: makeTrip(),
        activities: const [],
        flights: const [],
        accommodations: const [],
        baggageItems: const [],
        shares: const [],
        userRole: 'OWNER',
        selectedDayIndex: 0,
        deferredLoaded: true,
        sectionErrors: const {},
        completionResult: const CompletionResult(percentage: 0, segments: {}),
      ),
    );
  });

  Future<void> pump(WidgetTester tester, Widget panel) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: BlocProvider<TripDetailBloc>.value(value: bloc, child: panel),
        ),
      ),
    );
  }

  testWidgets('empty state shows CTA label when there is no summary or items', (
    tester,
  ) async {
    await pump(
      tester,
      const BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [],
        totalDays: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(ElegantEmptyState), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
  });

  testWidgets('shows recent expenses inline when items exist', (tester) async {
    final items = [
      _expense(id: 'e1', label: 'Coffee', amount: 4.5),
      _expense(
        id: 'e2',
        label: 'Lunch',
        amount: 25,
        category: BudgetCategory.food,
      ),
      _expense(
        id: 'e3',
        label: 'Museum',
        amount: 12,
        category: BudgetCategory.activity,
      ),
    ];
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: items,
        totalDays: 3,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Museum'), findsOneWidget);
    expect(find.text('RECENT'), findsOneWidget);
  });

  testWidgets('caps recent expenses to 5 even with more items', (tester) async {
    final items = List.generate(
      8,
      (i) => _expense(id: 'e$i', label: 'Item $i'),
    );
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: items,
        totalDays: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    for (var i = 0; i < 5; i++) {
      expect(find.text('Item $i'), findsOneWidget);
    }
    expect(find.text('Item 5'), findsNothing);
  });

  testWidgets('PanelFab is visible when canEdit is true', (tester) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [_expense()],
        totalDays: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(PanelFab), findsOneWidget);
  });

  testWidgets('PanelFab is hidden in viewer mode', (tester) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [_expense()],
        totalDays: 0,
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  testWidgets('BudgetStripe is rendered when summary has a total budget', (
    tester,
  ) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: const BudgetSummary(
          totalBudget: 1500,
          totalSpent: 600,
          byCategory: {'FOOD': 600},
        ),
        budgetItems: [_expense()],
        totalDays: 5,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.byType(BudgetStripe), findsOneWidget);
  });
}
