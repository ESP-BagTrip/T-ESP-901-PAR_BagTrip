// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/review_hero.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_programme_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/view/trip_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/test_fixtures.dart';

void main() {
  Widget buildHarness(HomeActiveTrip state) {
    // Intentionally NO parent Scaffold — the view must provide its own so it
    // renders correctly when pushed without one. Otherwise every descendant
    // Text gets Flutter's debug "missing Material" yellow underline overlay.
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: ActiveTripProgrammeView(state: state),
    );
  }

  HomeActiveTrip makeOngoingState() {
    final now = DateTime.now();
    final trip = makeTrip(
      status: TripStatus.ongoing,
      destinationName: 'Tokyo',
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
    );
    return HomeActiveTrip(
      user: makeUser(),
      activeTrip: trip,
      upcomingTrips: const [],
      allActivities: const [],
    );
  }

  testWidgets(
    'provides its own Scaffold so descendants find a Material ancestor',
    (tester) async {
      await tester.pumpWidget(buildHarness(makeOngoingState()));
      await tester.pump();

      // The Scaffold must be in-tree — that's what gives every Text descendant a
      // Material ancestor. If this assertion regresses, the debug "missing
      // Material" yellow double-underline reappears on every label in the view.
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    },
  );

  testWidgets('renders the programme title', (tester) async {
    await tester.pumpWidget(buildHarness(makeOngoingState()));
    await tester.pump();

    // Smoke render — the title is above the fold; ListView lazily builds the
    // rest, so deeper assertions belong in dedicated panel tests.
    expect(find.text('Schedule'), findsOneWidget);
  });

  testWidgets('hero scrolls with programme content in one CustomScrollView', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(makeOngoingState()));
    await tester.pump();

    expect(
      find.ancestor(
        of: find.byType(ReviewHero),
        matching: find.byType(CustomScrollView),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Schedule'),
        matching: find.byType(CustomScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows edit programme FAB with pen icon', (tester) async {
    await tester.pumpWidget(buildHarness(makeOngoingState()));
    await tester.pump();

    expect(find.byType(PanelFab), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.text('Edit schedule'), findsOneWidget);
  });

  testWidgets('edit programme FAB opens trip detail on activities tab', (
    tester,
  ) async {
    final state = makeOngoingState();
    final router = GoRouter(
      initialLocation: '/programme',
      routes: [
        GoRoute(
          path: '/programme',
          builder: (_, _) => ActiveTripProgrammeView(state: state),
        ),
        GoRoute(
          path: '/home/:tripId',
          builder: (_, goState) => Scaffold(
            body: Text(
              'trip-detail-${goState.pathParameters['tripId']}-'
              '${goState.uri.queryParameters['tab']}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(PanelFab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('trip-detail-trip-1-activities'), findsOneWidget);
  });

  testWidgets('back from trip detail returns to programme when pushed', (
    tester,
  ) async {
    final state = makeOngoingState();
    final router = GoRouter(
      initialLocation: '/programme',
      routes: [
        GoRoute(
          path: '/programme',
          builder: (_, _) => ActiveTripProgrammeView(state: state),
        ),
        GoRoute(
          path: '/home/:tripId',
          builder: (context, goState) => Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => leaveTripDetail(context)),
            ),
            body: Text(
              'trip-detail-${goState.pathParameters['tripId']}-'
              '${goState.uri.queryParameters['tab']}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byType(PanelFab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('trip-detail-trip-1-activities'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('trip-detail-trip-1-activities'), findsNothing);
  });
}
