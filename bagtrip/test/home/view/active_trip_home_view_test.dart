import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/active_trip_home_view.dart';
import 'package:bagtrip/home/widgets/home_two_zone_layout.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';
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
    List<Trip> upcomingTrips = const [],
    List<Activity> allActivities = const [],
    int completionPercentage = 0,
  }) {
    final user = makeUser(fullName: fullName);
    final now = DateTime.now();
    final trip = makeTrip(
      status: TripStatus.ongoing,
      destinationName: destinationName,
      startDate: now.subtract(const Duration(days: 2)),
      endDate: now.add(const Duration(days: 5)),
    ).copyWith(completionPercentage: completionPercentage);

    final state = HomeActiveTrip(
      user: user,
      activeTrip: trip,
      upcomingTrips: upcomingTrips,
      allActivities: allActivities,
    );

    when(() => mockHomeBloc.state).thenReturn(state);

    return localizedRouterApp(
      child: BlocProvider<HomeBloc>.value(
        value: mockHomeBloc,
        child: Scaffold(
          body: TickerMode(
            enabled: false,
            child: ActiveTripHomeView(state: state),
          ),
        ),
      ),
    );
  }

  group('ActiveTripHomeView', () {
    testWidgets('uses two-zone layout with primaryDark background', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeTwoZoneLayout), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == ColorName.primaryDark,
        ),
        findsWidgets,
      );
    });

    testWidgets('shows trip in progress eyebrow', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('TRIP IN PROGRESS'), findsOneWidget);
    });

    testWidgets('hero shows destination name', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Tokyo'), findsOneWidget);
    });

    testWidgets('shows completion ring', (tester) async {
      await tester.pumpWidget(buildApp(completionPercentage: 42));
      await tester.pumpAndSettle();

      expect(find.byType(CompletionRing), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('shows highlight activity title', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await tester.pumpWidget(
        buildApp(
          allActivities: [
            makeActivity(
              id: 'next',
              title: 'Sushi dinner',
              date: today,
              startTime: '23:59',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sushi dinner'), findsOneWidget);
      expect(find.text('Trip progress'), findsNothing);
    });

    testWidgets('shows empty activities message when none upcoming', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No activities planned today'), findsOneWidget);
    });

    testWidgets('shows Plan a trip card', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Plan a trip'), findsOneWidget);
    });

    testWidgets('shows upcoming trips section when present', (tester) async {
      await tester.pumpWidget(
        buildApp(upcomingTrips: [makeTrip(status: TripStatus.planned)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming trip'), findsOneWidget);
      expect(find.text('Paris'), findsOneWidget);
    });
  });
}
