import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/widgets/quick_actions_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('QuickActionsRow', () {
    testWidgets('draft status shows 3 owner actions', (tester) async {
      final trip = makeTrip();
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add flight'), findsOneWidget);
      expect(find.text('Add hotel'), findsOneWidget);
      expect(find.text('Add activity'), findsOneWidget);
    });

    testWidgets('planned status shows same 3 actions', (tester) async {
      final trip = makeTrip(status: TripStatus.planned);
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add flight'), findsOneWidget);
      expect(find.text('Add hotel'), findsOneWidget);
      expect(find.text('Add activity'), findsOneWidget);
    });

    testWidgets('ongoing status shows 3 actions', (tester) async {
      final trip = makeTrip(status: TripStatus.ongoing);
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Baggage'), findsOneWidget);
    });

    testWidgets('completed status shows 1 action', (tester) async {
      final trip = makeTrip(status: TripStatus.completed);
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Souvenirs'), findsOneWidget);
    });

    testWidgets('viewer role shows only read-only actions', (tester) async {
      final trip = makeTrip(status: TripStatus.ongoing);
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Flights'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      // Should not show owner actions
      expect(find.text('Expense'), findsNothing);
      expect(find.text('Baggage'), findsNothing);
    });

    testWidgets('correct icons match each action', (tester) async {
      final trip = makeTrip(status: TripStatus.ongoing);
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wallet_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hiking_rounded), findsOneWidget);
      expect(find.byIcon(Icons.luggage_rounded), findsOneWidget);
    });

    testWidgets('animation completes without error', (tester) async {
      final trip = makeTrip();
      await tester.pumpWidget(
        _buildApp(
          child: QuickActionsRow(
            trip: trip,
            tripId: trip.id,
            isViewer: false,
            isCompleted: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(QuickActionsRow), findsOneWidget);
    });
  });
}
