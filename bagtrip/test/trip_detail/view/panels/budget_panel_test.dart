// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
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

BudgetItem _item({
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

  testWidgets('both sections render even when there is no item yet', (
    tester,
  ) async {
    await pump(
      tester,
      const BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [],
        activities: [],
        totalDays: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    // Both section headers and their empty hints are visible on a fresh trip.
    expect(find.text('FORECAST'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
    expect(find.textContaining('No forecast yet'), findsOneWidget);
    expect(find.textContaining('No expense logged yet'), findsOneWidget);
  });

  testWidgets('renders both Forecast and Real section headers', (tester) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [_item(isPlanned: true)],
        activities: const [],
        totalDays: 3,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('FORECAST'), findsOneWidget);
    expect(find.text('REAL'), findsOneWidget);
  });

  testWidgets('forecast items appear under Forecast, real under Real', (
    tester,
  ) async {
    final items = [
      _item(id: 'f1', label: 'Forecast hotel', amount: 120, isPlanned: true),
      _item(id: 'r1', label: 'Lunch', amount: 25, isPlanned: false),
    ];
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: items,
        activities: const [],
        totalDays: 3,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.text('Forecast hotel'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
  });

  testWidgets('empty forecast section surfaces its empty hint', (tester) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [_item(isPlanned: false)],
        activities: const [],
        totalDays: 0,
        canEdit: true,
        isCompleted: false,
        role: 'OWNER',
      ),
    );
    expect(find.textContaining('No forecast yet'), findsOneWidget);
  });

  testWidgets(
    'projects activities into the budget sections by validation status',
    (tester) async {
      // Phase B3 (SMP-325) regression: activities are the single source
      // of truth for their own costs. The panel surfaces them as
      // read-only rows next to the budget items so the user gets a
      // unified spend view without the legacy duplication that used
      // to mirror each activity into a BudgetItem.
      final suggested = makeActivity(
        id: 'a-suggested',
        title: 'Massage',
        validationStatus: ValidationStatus.suggested,
      ).copyWith(estimatedCost: 60);
      final validated = makeActivity(
        id: 'a-validated',
        title: 'Louvre',
        validationStatus: ValidationStatus.validated,
      ).copyWith(estimatedCost: 22);
      await pump(
        tester,
        BudgetPanel(
          tripId: 'trip-1',
          budgetSummary: null,
          budgetItems: const [],
          activities: [suggested, validated],
          totalDays: 3,
          canEdit: true,
          isCompleted: false,
          role: 'OWNER',
        ),
      );
      // Both activity costs appear in the panel — once each, never twice.
      expect(find.text('Massage'), findsOneWidget);
      expect(find.text('Louvre'), findsOneWidget);
      // Activities are read-only on the budget tab: tapping them must
      // never spawn the budget item edit sheet (the editing path is the
      // Activities tab, which keeps the validation flow centralised).
      // We assert that by confirming the row is not wrapped in a
      // Dismissible (which is how editable budget rows surface a
      // swipe-to-delete).
      expect(find.byType(Dismissible), findsNothing);
    },
  );

  testWidgets('PanelFab is visible when canEdit is true', (tester) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: null,
        budgetItems: [_item()],
        activities: const [],
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
        budgetItems: [_item()],
        activities: const [],
        totalDays: 0,
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    expect(find.byType(PanelFab), findsNothing);
  });

  // ── Topic 06 (B9) — VIEWER renders only the semantic bucket ──────

  testWidgets('viewer mode renders the budgetStatus bucket, not the items', (
    tester,
  ) async {
    await pump(
      tester,
      BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: const BudgetSummary(
          totalBudget: 1000,
          budgetStatus: 'tight',
        ),
        // Items list is a server-side leak guard but even if a client
        // mock passes one, the viewer panel must NOT render it.
        budgetItems: [_item(label: 'Should not appear')],
        activities: const [],
        totalDays: 5,
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );

    // Bucket label visible
    expect(find.text('Tight'), findsOneWidget);
    // Hint visible
    expect(find.textContaining('owner only'), findsOneWidget);
    // Forecast / Real sections must NOT render
    expect(find.text('FORECAST'), findsNothing);
    expect(find.text('REAL'), findsNothing);
    // Item label must NOT leak
    expect(find.text('Should not appear'), findsNothing);
  });

  testWidgets('viewer with no budget target renders dash + no bucket', (
    tester,
  ) async {
    await pump(
      tester,
      const BudgetPanel(
        tripId: 'trip-1',
        budgetSummary: BudgetSummary(totalBudget: 0, budgetStatus: null),
        budgetItems: [],
        activities: [],
        totalDays: 0,
        canEdit: false,
        isCompleted: false,
        role: 'VIEWER',
      ),
    );
    // Dash placeholder for missing target
    expect(find.text('—'), findsOneWidget);
    // No status pill
    expect(find.text('On track'), findsNothing);
    expect(find.text('Tight'), findsNothing);
    expect(find.text('Over budget'), findsNothing);
  });

  testWidgets('viewer mode maps each status to its localised label', (
    tester,
  ) async {
    for (final (status, expected) in [
      ('onTrack', 'On track'),
      ('tight', 'Tight'),
      ('overBudget', 'Over budget'),
    ]) {
      await pump(
        tester,
        BudgetPanel(
          tripId: 'trip-1',
          budgetSummary: BudgetSummary(totalBudget: 1000, budgetStatus: status),
          budgetItems: const [],
          activities: const [],
          totalDays: 5,
          canEdit: false,
          isCompleted: false,
          role: 'VIEWER',
        ),
      );
      expect(
        find.text(expected),
        findsOneWidget,
        reason: 'status $status should render as "$expected"',
      );
    }
  });
}
