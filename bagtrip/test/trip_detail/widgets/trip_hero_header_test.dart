import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/widgets/trip_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

Widget _buildApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SizedBox(height: 300, child: child)),
  );
}

void main() {
  group('TripHeroHeader', () {
    testWidgets('upcoming state shows countdown', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(),
            dateRange: '01/06 - 07/06',
            daysUntilTrip: 10,
            totalDays: 7,
            isCompleted: false,
            isOngoing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('In 10 days'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('ongoing state shows day progress', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(status: TripStatus.ongoing),
            dateRange: '01/06 - 07/06',
            currentDay: 3,
            totalDays: 7,
            isCompleted: false,
            isOngoing: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day 3 of 7'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('completed state shows badge', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(status: TripStatus.completed),
            dateRange: '01/06 - 07/06',
            totalDays: 7,
            isCompleted: true,
            isOngoing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('gradient fallback when no cover image', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(),
            dateRange: '01/06 - 07/06',
            daysUntilTrip: 5,
            totalDays: 7,
            isCompleted: false,
            isOngoing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    });

    testWidgets('Hero tag present with correct trip id', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(id: 'abc-123'),
            dateRange: '01/06 - 07/06',
            daysUntilTrip: 5,
            totalDays: 7,
            isCompleted: false,
            isOngoing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'trip-abc-123');
    });

    testWidgets('displays destination and dates', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          child: TripHeroHeader(
            trip: makeTrip(),
            dateRange: '01/06 - 07/06',
            daysUntilTrip: 5,
            totalDays: 7,
            isCompleted: false,
            isOngoing: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('01/06 - 07/06'), findsOneWidget);
    });
  });
}
