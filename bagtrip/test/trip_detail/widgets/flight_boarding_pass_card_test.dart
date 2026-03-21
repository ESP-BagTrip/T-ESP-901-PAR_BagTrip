import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/trip_detail/widgets/flight_boarding_pass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('FlightBoardingPassCard', () {
    testWidgets('renders flight number, airline, airport codes, times', (
      tester,
    ) async {
      final flight = makeManualFlight(
        flightNumber: 'AF1234',
        departureDate: DateTime(2024, 6, 12, 8, 30),
        arrivalDate: DateTime(2024, 6, 12, 14, 45),
      );

      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: flight,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AF1234'), findsOneWidget);
      expect(find.text('Air France'), findsOneWidget);
      expect(find.text('CDG'), findsOneWidget);
      expect(find.text('JFK'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('14:45'), findsOneWidget);
    });

    testWidgets('confirmed flight → green "Confirmed" badge', (tester) async {
      final flight = makeManualFlight(
        departureDate: DateTime(2024, 6, 12, 8, 30),
        arrivalDate: DateTime(2024, 6, 12, 14, 45),
      );

      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: flight,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
    });

    testWidgets('pending flight → orange "Pending" badge', (tester) async {
      final flight = makeManualFlight(airline: null);

      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: flight,
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('OWNER not completed → Dismissible present', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: makeManualFlight(),
            isOwner: true,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('swipe triggers onDelete for OWNER', (tester) async {
      var deleted = false;

      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: makeManualFlight(),
            isOwner: true,
            isCompleted: false,
            onDelete: () => deleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(find.byType(Dismissible), const Offset(-500, 0), 1000);
      await tester.pumpAndSettle();

      expect(deleted, true);
    });

    testWidgets('VIEWER → no Dismissible', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: makeManualFlight(),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('COMPLETED OWNER → no Dismissible', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: FlightBoardingPassCard(
            flight: makeManualFlight(),
            isOwner: true,
            isCompleted: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('missing airports → "---", missing times → "--:--"', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          child: const FlightBoardingPassCard(
            flight: ManualFlight(
              id: 'f1',
              tripId: 'trip-1',
              flightNumber: 'XX999',
            ),
            isOwner: false,
            isCompleted: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('---'), findsNWidgets(2));
      expect(find.text('--:--'), findsNWidgets(2));
    });
  });
}
