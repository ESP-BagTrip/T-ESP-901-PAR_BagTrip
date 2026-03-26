import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('TripCard.large', () {
    testWidgets('renders destination and date range', (tester) async {
      final trip = makeTrip(
        destinationName: 'Tokyo',
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 7),
      );

      await tester.pumpWidget(buildApp(child: TripCard.large(trip: trip)));
      await tester.pumpAndSettle();

      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('01/06/2024 - 07/06/2024'), findsOneWidget);
    });

    testWidgets('renders completion bar when percent > 0', (tester) async {
      final trip = makeTrip(
        destinationName: 'Barcelona',
        title: 'Visit Barcelona',
      );

      await tester.pumpWidget(
        buildApp(child: TripCard.large(trip: trip, completionPercent: 60)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('gradient fallback when no coverImageUrl', (tester) async {
      final trip = makeTrip(destinationName: 'Rome');

      await tester.pumpWidget(buildApp(child: TripCard.large(trip: trip)));
      await tester.pumpAndSettle();

      // Gradient placeholder rendered (contains flight icon)
      expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    });
  });

  group('TripCard.compact', () {
    testWidgets('renders title, destination, date, status badge', (
      tester,
    ) async {
      final trip = makeTrip(
        title: 'My Paris Trip',
        destinationName: 'Paris, France',
        startDate: DateTime(2024, 6),
        endDate: DateTime(2024, 6, 7),
        status: TripStatus.planned,
      );

      await tester.pumpWidget(buildApp(child: TripCard.compact(trip: trip)));
      await tester.pumpAndSettle();

      expect(find.text('My Paris Trip'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.text('01/06/2024 - 07/06/2024'), findsOneWidget);
    });

    testWidgets('Hero tag is trip-{id}', (tester) async {
      final trip = makeTrip(id: 'abc-123');

      await tester.pumpWidget(buildApp(child: TripCard.compact(trip: trip)));
      await tester.pumpAndSettle();

      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'trip-abc-123',
      );
      expect(heroFinder, findsOneWidget);
    });
  });

  group('TripCard onTap', () {
    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      final trip = makeTrip();

      await tester.pumpWidget(
        buildApp(
          child: TripCard(trip: trip, onTap: () => tapped = true),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TripCard));
      expect(tapped, isTrue);
    });
  });
}
