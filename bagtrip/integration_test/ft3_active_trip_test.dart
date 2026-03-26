import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/e2e_fixtures.dart';
import 'helpers/finders.dart' as f;
import 'helpers/mock_di_setup.dart';
import 'helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerE2eFallbackValues();
  });

  group('FT3 — Active trip (in-trip mode)', () {
    testWidgets(
      'home renders ActiveTripHomeView with today\'s activities and weather',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final trip = makeTrip(
          id: 'trip-active',
          title: 'Barcelona Adventure',
          status: TripStatus.ongoing,
          destinationName: 'Barcelona',
          startDate: today,
          endDate: today.add(const Duration(days: 5)),
        );

        final todayActivities = [
          makeActivity(
            id: 'act-morning',
            tripId: 'trip-active',
            title: 'Morning Museum',
            date: today,
          ),
          makeActivity(
            id: 'act-lunch',
            tripId: 'trip-active',
            title: 'Tapas Lunch',
            date: today,
            startTime: '12:30',
            category: ActivityCategory.food,
          ),
          makeActivity(
            id: 'act-afternoon',
            tripId: 'trip-active',
            title: 'Beach Walk',
            date: today,
            startTime: '15:00',
            category: ActivityCategory.sport,
          ),
        ];
        final tomorrowActivity = makeActivity(
          id: 'act-tomorrow',
          tripId: 'trip-active',
          title: 'Tomorrow Beach',
          date: today.add(const Duration(days: 1)),
          startTime: '10:00',
        );

        final mocks = await setupTestServiceLocator();

        stubActiveTripHome(
          mocks,
          trip,
          activities: [...todayActivities, tomorrowActivity],
          weather: const WeatherSummary(avgTempC: 28, description: 'Sunny'),
        );

        await pumpTestApp(tester, existingMocks: mocks);

        // Verify ActiveTripHomeView renders
        expect(f.homeActiveTrip, findsOneWidget);
        expect(f.activeTripHomeView, findsOneWidget);
        expect(f.homeNewUser, findsNothing);
        expect(f.homeTripManager, findsNothing);
      },
    );

    testWidgets(
      'HomeBloc emits HomeActiveTrip with 3 today activities and weather',
      (tester) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final trip = makeTrip(
          id: 'trip-active-2',
          title: 'Barcelona',
          status: TripStatus.ongoing,
          destinationName: 'Barcelona',
          startDate: today,
          endDate: today.add(const Duration(days: 5)),
        );

        final activities = [
          makeActivity(
            id: 'a1',
            tripId: 'trip-active-2',
            title: 'Morning Museum',
            date: today,
          ),
          makeActivity(
            id: 'a2',
            tripId: 'trip-active-2',
            title: 'Lunch',
            date: today,
            startTime: '12:30',
          ),
          makeActivity(
            id: 'a3',
            tripId: 'trip-active-2',
            title: 'Afternoon',
            date: today,
            startTime: '15:00',
          ),
          makeActivity(
            id: 'a4',
            tripId: 'trip-active-2',
            title: 'Tomorrow Beach',
            date: today.add(const Duration(days: 1)),
            startTime: '10:00',
          ),
        ];

        final mocks = await setupTestServiceLocator();

        stubActiveTripHome(
          mocks,
          trip,
          activities: activities,
          weather: const WeatherSummary(avgTempC: 28, description: 'Sunny'),
        );

        await pumpTestApp(tester, existingMocks: mocks);

        // Verify HomeBloc state
        final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();
        final state = homeBloc.state;
        expect(state, isA<HomeActiveTrip>());
        final activeState = state as HomeActiveTrip;

        // Today: 3 activities (tomorrow excluded)
        expect(activeState.todayActivities.length, 3);
        expect(activeState.allActivities.length, 4);

        // Weather
        expect(activeState.weatherSummary, contains('28'));
        expect(activeState.weatherSummary, contains('Sunny'));

        // Trip info
        expect(activeState.activeTrip.id, 'trip-active-2');
        expect(activeState.currentDay, 1);
      },
    );

    testWidgets('home with no weather still renders ActiveTripHomeView', (
      tester,
    ) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final trip = makeTrip(
        id: 'trip-no-weather',
        title: 'Barcelona',
        status: TripStatus.ongoing,
        destinationName: 'Barcelona',
        startDate: today,
        endDate: today.add(const Duration(days: 3)),
      );

      final mocks = await setupTestServiceLocator();
      stubActiveTripHome(mocks, trip); // No weather, no activities

      await pumpTestApp(tester, existingMocks: mocks);

      expect(f.homeActiveTrip, findsOneWidget);

      final homeBloc = tester.element(f.homeActiveTrip).read<HomeBloc>();
      final state = homeBloc.state as HomeActiveTrip;
      expect(state.weatherSummary, isNull);
      expect(state.todayActivities, isEmpty);
    });
  });
}
