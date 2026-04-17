import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart'
    show ActiveTripHomeView, tomorrowSectionHeaderKey;
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockHomeBloc extends Mock implements HomeBloc {}

void main() {
  late MockHomeBloc mockHomeBloc;

  setUp(() {
    mockHomeBloc = MockHomeBloc();
    when(() => mockHomeBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockHomeBloc.close()).thenAnswer((_) async {});
  });

  Widget buildApp(HomeActiveTrip state) {
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

  group('Tomorrow preview', () {
    testWidgets('shows "TOMORROW" header when tomorrow activities exist', (
      tester,
    ) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final activities = [
        makeActivity(
          id: 'tom-1',
          title: 'Tomorrow Activity',
          date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
          startTime: '10:00',
        ),
      ];

      final state = HomeActiveTrip(
        user: makeUser(),
        activeTrip: makeTrip(
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
        ),
        allActivities: activities,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('shows activity count badge', (tester) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final activities = [
        makeActivity(
          id: 'tom-1',
          title: 'Breakfast',
          date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
          startTime: '08:00',
        ),
        makeActivity(
          id: 'tom-2',
          title: 'Lunch',
          date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
          startTime: '12:00',
        ),
      ];

      final state = HomeActiveTrip(
        user: makeUser(),
        activeTrip: makeTrip(
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
        ),
        allActivities: activities,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('2 activities'), findsOneWidget);
    });

    testWidgets('shows "Last day of the trip" badge on last day', (
      tester,
    ) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final activities = [
        makeActivity(
          id: 'last-1',
          title: 'Final Activity',
          date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
          startTime: '10:00',
        ),
      ];

      final state = HomeActiveTrip(
        user: makeUser(),
        activeTrip: makeTrip(
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 3)),
          // Trip ends tomorrow = last day
          endDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
        ),
        allActivities: activities,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Last day of the trip'), findsOneWidget);
    });

    testWidgets('does not show tomorrow section when no tomorrow activities', (
      tester,
    ) async {
      final now = DateTime.now();
      final state = HomeActiveTrip(
        user: makeUser(),
        activeTrip: makeTrip(
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
        ),
        allActivities: [],
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(seconds: 1));

      // The "Tomorrow" text may also appear as a QuickActionsBar entry when
      // the CI runner is in the evening (hour >= 18 UTC). Assert directly on
      // the section header key so the test stays deterministic.
      expect(find.byKey(tomorrowSectionHeaderKey), findsNothing);
    });

    testWidgets('collapses to 3 items when >3 activities, shows "Show all"', (
      tester,
    ) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      );

      final activities = List.generate(
        5,
        (i) => makeActivity(
          id: 'tom-$i',
          title: 'Activity $i',
          date: tomorrowDate,
          startTime: '${(8 + i).toString().padLeft(2, '0')}:00',
        ),
      );

      final state = HomeActiveTrip(
        user: makeUser(),
        activeTrip: makeTrip(
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 5)),
        ),
        allActivities: activities,
      );

      await tester.pumpWidget(buildApp(state));
      await tester.pump(const Duration(seconds: 1));

      // Scroll down to reveal the "Show all" button
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump(const Duration(seconds: 1));

      // "Show all (5)" button should exist
      expect(find.textContaining('Show all'), findsOneWidget);
    });
  });
}
