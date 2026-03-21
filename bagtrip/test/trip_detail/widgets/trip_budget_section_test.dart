import 'package:bagtrip/budget/widgets/budget_alert_banner.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/widgets/trip_budget_section.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockTripDetailBloc extends MockBloc<TripDetailEvent, TripDetailState>
    implements TripDetailBloc {}

Widget _buildApp({required Widget child, required TripDetailBloc bloc}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: BlocProvider<TripDetailBloc>.value(
      value: bloc,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  late MockTripDetailBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(RefreshTripDetail());
  });

  setUp(() {
    mockBloc = MockTripDetailBloc();
  });

  group('TripBudgetSection', () {
    testWidgets('header shows "Budget" + wallet icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: null,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budget'), findsOneWidget);
      expect(find.byIcon(Icons.wallet_rounded), findsAtLeast(1));
    });

    testWidgets('header shows % badge when summary exists', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(percentConsumed: 40.5),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('41%'), findsOneWidget);
    });

    testWidgets('dashboard renders amounts', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(
              totalBudget: 1500,
              totalSpent: 500,
              remaining: 1000,
            ),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1500.00 \u20ac'), findsOneWidget);
      expect(find.text('500.00 \u20ac'), findsOneWidget);
      expect(find.text('1000.00 \u20ac'), findsOneWidget);
    });

    testWidgets('categories render colored breakdown rows', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(
              byCategory: {'flight': 200, 'food': 100},
            ),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Meals'), findsOneWidget);
      expect(find.text('200.00 \u20ac'), findsOneWidget);
      expect(find.text('100.00 \u20ac'), findsOneWidget);
    });

    testWidgets('alert → BudgetAlertBanner displayed', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(
              alertLevel: 'WARNING',
              totalSpent: 850,
            ),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BudgetAlertBanner), findsOneWidget);
    });

    testWidgets('empty OWNER → 2 CTA tiles', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: null,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estimate my budget'), findsOneWidget);
      expect(find.text('Add expense'), findsOneWidget);
    });

    testWidgets('empty VIEWER → no CTAs', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: null,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track your expenses'), findsOneWidget);
      expect(find.text('Estimate my budget'), findsNothing);
      expect(find.text('Add expense'), findsNothing);
    });

    testWidgets('empty COMPLETED → no CTAs', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: null,
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Track your expenses'), findsOneWidget);
      expect(find.text('Estimate my budget'), findsNothing);
      expect(find.text('Add expense'), findsNothing);
    });

    testWidgets('manage button visible for owner', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage budget'), findsOneWidget);
    });

    testWidgets('manage button hidden for viewer', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          bloc: mockBloc,
          child: TripBudgetSection(
            budgetSummary: makeBudgetSummary(),
            tripId: 'trip-1',
            trip: makeTrip(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manage budget'), findsNothing);
    });
  });
}
