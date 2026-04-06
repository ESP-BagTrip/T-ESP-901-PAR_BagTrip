import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/trip_manager_home_view.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockTripManagementBloc
    extends MockBloc<TripManagementEvent, TripManagementState>
    implements TripManagementBloc {}

void main() {
  late MockTripManagementBloc mockTripBloc;

  setUp(() {
    mockTripBloc = MockTripManagementBloc();
    when(() => mockTripBloc.state).thenReturn(TripManagementInitial());
  });

  Widget buildApp({
    String? fullName = 'Test User',
    bool hasNextTrip = true,
    int nextTripCompletion = 40,
    int daysUntil = 5,
  }) {
    final user = makeUser(fullName: fullName);
    final nextTrip = hasNextTrip
        ? makeTrip(
            id: 'next-1',
            status: TripStatus.planned,
            destinationName: 'Tokyo',
            startDate: DateTime.now().add(Duration(days: daysUntil)),
          )
        : null;

    final state = HomeTripManager(
      user: user,
      nextTrip: nextTrip,
      nextTripCompletion: nextTripCompletion,
      upcomingTrips: nextTrip != null ? [nextTrip] : [],
      completedTrips: [],
    );

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: BlocProvider<TripManagementBloc>.value(
          value: mockTripBloc,
          child: TripManagerHomeView(state: state),
        ),
      ),
    );
  }

  group('TripManagerHomeView', () {
    testWidgets('greeting displays user name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: 'Alice Smith'));
      // Use pump with duration — shimmer never settles
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Welcome, Alice'), findsOneWidget);
    });

    testWidgets('greeting fallback when no name', (tester) async {
      await tester.pumpWidget(buildApp(fullName: null));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('NextTripHero visible when hasNextTrip', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tokyo'), findsOneWidget);
    });

    testWidgets('NextTripHero hidden when no next trip', (tester) async {
      await tester.pumpWidget(buildApp(hasNextTrip: false));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Tokyo'), findsNothing);
    });

    testWidgets('countdown text is visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      // daysUntilNextTrip depends on DateTime.now(), so check prefix
      expect(find.textContaining('In '), findsOneWidget);
    });

    testWidgets('PlanTripCta visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Plan a trip'), findsOneWidget);
    });

    testWidgets('MY TRIPS section header visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MY TRIPS'), findsOneWidget);
    });

    testWidgets('segment control shows 3 tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });
  });
}
