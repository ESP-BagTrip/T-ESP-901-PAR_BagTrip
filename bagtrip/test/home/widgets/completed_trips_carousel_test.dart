import 'package:bagtrip/home/widgets/completed_trips_carousel.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildApp({required List<Trip> trips}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: CompletedTripsCarousel(completedTrips: trips)),
    );
  }

  group('CompletedTripsCarousel', () {
    testWidgets('renders nothing when empty list', (tester) async {
      await tester.pumpWidget(buildApp(trips: []));
      await tester.pumpAndSettle();

      expect(find.byType(CompletedTripsCarousel), findsOneWidget);
      expect(find.text('PAST ADVENTURES'), findsNothing);
    });

    testWidgets('section header visible', (tester) async {
      final trips = [
        makeTrip(id: 'c1', status: TripStatus.completed, title: 'Rome 2023'),
      ];

      await tester.pumpWidget(buildApp(trips: trips));
      await tester.pumpAndSettle();

      expect(find.text('PAST ADVENTURES'), findsOneWidget);
    });

    testWidgets('cards rendered with desaturation filter', (tester) async {
      final trips = [
        makeTrip(id: 'c1', status: TripStatus.completed, title: 'Rome 2023'),
        makeTrip(id: 'c2', status: TripStatus.completed, title: 'London'),
      ];

      await tester.pumpWidget(buildApp(trips: trips));
      await tester.pumpAndSettle();

      // ColorFiltered wraps each card for grayscale effect
      expect(find.byType(ColorFiltered), findsWidgets);
      // At least one TripCard rendered
      expect(find.byType(TripCard), findsWidgets);
    });
  });
}
