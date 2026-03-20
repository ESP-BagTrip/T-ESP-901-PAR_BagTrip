import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildApp({
    String? fullName = 'Test User',
    String destinationName = 'Tokyo',
    List<Activity>? allActivities,
    String? weatherSummary,
  }) {
    final user = makeUser(fullName: fullName);
    final now = DateTime.now();
    final trip = makeTrip(
      status: TripStatus.ongoing,
      destinationName: destinationName,
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
    );

    final state = HomeActiveTrip(
      user: user,
      activeTrip: trip,
      allActivities: allActivities ?? const [],
      weatherSummary: weatherSummary,
    );

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: ActiveTripHomeView(state: state)),
    );
  }

  group('ActiveTripHomeView', () {
    testWidgets('greeting shows user name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: 'Alice Smith'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Welcome back, Alice'), findsOneWidget);
    });

    testWidgets('greeting fallback when no name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: null));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('hero shows destination', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Your trip to Tokyo'), findsOneWidget);
    });

    testWidgets('hero shows day counter', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Day '), findsOneWidget);
    });

    testWidgets('activities timeline renders', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activities = [
        makeActivity(id: 'a1', date: today),
        makeActivity(
          id: 'a2',
          title: 'Lunch at Cafe',
          date: today,
          startTime: '12:00',
        ),
      ];

      await tester.pumpWidget(buildApp(allActivities: activities));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Visit Eiffel Tower'), findsOneWidget);
      expect(find.text('Lunch at Cafe'), findsOneWidget);
    });

    testWidgets('activities sorted by time', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activities = [
        makeActivity(
          id: 'a1',
          title: 'Dinner',
          date: today,
          startTime: '19:00',
        ),
        makeActivity(
          id: 'a2',
          title: 'Breakfast',
          date: today,
          startTime: '08:00',
        ),
      ];

      await tester.pumpWidget(buildApp(allActivities: activities));
      await tester.pump(const Duration(seconds: 1));

      final breakfastOffset = tester.getTopLeft(find.text('Breakfast'));
      final dinnerOffset = tester.getTopLeft(find.text('Dinner'));

      expect(breakfastOffset.dy, lessThan(dinnerOffset.dy));
    });

    testWidgets('empty state when no activities', (tester) async {
      await tester.pumpWidget(buildApp(allActivities: []));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('No activities planned today'), findsOneWidget);
    });

    testWidgets('quick actions visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Baggage'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('PlanTripCta visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      await tester.scrollUntilVisible(find.text('Plan a trip'), 200);
      expect(find.text('Plan a trip'), findsOneWidget);
    });

    testWidgets('weather shown when present', (tester) async {
      await tester.pumpWidget(buildApp(weatherSummary: '25°C Sunny'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('25°C Sunny'), findsOneWidget);
    });

    testWidgets('weather hidden when null', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('25°C Sunny'), findsNothing);
    });
  });
}
