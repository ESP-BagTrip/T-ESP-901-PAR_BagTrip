import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/widgets/active_trip_weather_card.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState> implements HomeBloc {}

void main() {
  late MockHomeBloc mockHomeBloc;

  setUp(() {
    mockHomeBloc = MockHomeBloc();
  });

  Widget buildApp({
    String? fullName = 'Test User',
    String destinationName = 'Tokyo',
    List<Activity>? allActivities,
    WeatherSummary? weatherData,
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
      weatherData: weatherData,
      weatherSummary: weatherData != null
          ? '${weatherData.avgTempC.round()}°C · ${weatherData.description}'
          : null,
    );

    when(() => mockHomeBloc.state).thenReturn(state);

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<HomeBloc>.value(
        value: mockHomeBloc,
        child: Scaffold(body: ActiveTripHomeView(state: state)),
      ),
    );
  }

  group('ActiveTripHomeView', () {
    testWidgets('shows trip in progress eyebrow', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('TRIP IN PROGRESS'), findsOneWidget);
    });

    testWidgets('hero shows destination name', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tokyo'), findsOneWidget);
    });

    testWidgets('hero shows day counter', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Day '), findsOneWidget);
    });

    testWidgets('activities timeline renders', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      expect(find.text('No activities on this day'), findsOneWidget);
    });

    testWidgets('quick actions section visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Quick actions'), findsOneWidget);
    });

    testWidgets('PlanTripCta not visible in active trip view', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Plan a trip'), findsNothing);
    });

    testWidgets('hero weather pill shows min–max and is not tappable', (
      tester,
    ) async {
      final weather = const WeatherSummary(
        avgTempC: 8,
        minTempC: 5,
        maxTempC: 12,
        description: 'Cloudy',
        rainProbability: 25,
        source: 'test',
      );
      await tester.pumpWidget(buildApp(weatherData: weather));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ActiveTripWeatherCard), findsOneWidget);
      expect(find.text('5°C – 12°C'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ActiveTripWeatherCard),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('weather card shows unavailable when no weather data', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Weather unavailable'), findsOneWidget);
    });
  });
}
