import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/weather_repository.dart';
import 'package:bagtrip/service/trip_notification_scheduler.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockTripNotificationScheduler extends Mock
    implements TripNotificationScheduler {}

class MockPostTripDismissalStorage extends Mock
    implements PostTripDismissalStorage {}

void main() {
  late MockTripRepository mockTripRepo;
  late MockAuthRepository mockAuthRepo;
  late MockActivityRepository mockActivityRepo;
  late MockConnectivityService mockConnectivity;
  late MockWeatherRepository mockWeatherRepo;
  late MockTripNotificationScheduler mockScheduler;
  late MockPostTripDismissalStorage mockDismissalStorage;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAuthRepo = MockAuthRepository();
    mockActivityRepo = MockActivityRepository();
    mockConnectivity = MockConnectivityService();
    mockWeatherRepo = MockWeatherRepository();
    mockScheduler = MockTripNotificationScheduler();
    mockDismissalStorage = MockPostTripDismissalStorage();

    registerFallbackValue(makeTrip());

    when(() => mockConnectivity.isOnline).thenReturn(true);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockScheduler.scheduleOngoingNotifications(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.schedulePackingReminder(any()),
    ).thenAnswer((_) async {});
  });

  HomeBloc buildBloc() => HomeBloc(
    tripRepository: mockTripRepo,
    authRepository: mockAuthRepo,
    activityRepository: mockActivityRepo,
    connectivityService: mockConnectivity,
    weatherRepository: mockWeatherRepo,
    scheduler: mockScheduler,
    dismissalStorage: mockDismissalStorage,
  );

  void stubUserAndTrips({
    List<Trip> ongoing = const [],
    List<Trip> planned = const [],
    List<Trip> completed = const [],
  }) {
    when(
      () => mockAuthRepo.getCurrentUser(),
    ).thenAnswer((_) async => Success(makeUser()));
    when(
      () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(makePaginatedResponse(items: ongoing, total: ongoing.length)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(makePaginatedResponse(items: planned, total: planned.length)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
    ).thenAnswer(
      (_) async => Success(
        makePaginatedResponse(items: completed, total: completed.length),
      ),
    );
  }

  group('In-trip detection integration', () {
    blocTest<HomeBloc, HomeState>(
      'app launch with trip starting today → mode active, HomeActiveTrip emitted',
      build: () {
        final now = DateTime.now();
        final tripStartingToday = makeTrip(
          id: 'today-trip',
          status: TripStatus.ongoing,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: now.add(const Duration(days: 5)),
        );

        stubUserAndTrips(ongoing: [tripStartingToday]);

        when(
          () => mockActivityRepo.getActivities('today-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(() => mockWeatherRepo.getWeather('today-trip')).thenAnswer(
          (_) async =>
              const Success(WeatherSummary(avgTempC: 22, description: 'Sunny')),
        );

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        expect(state.activeTrip.id, 'today-trip');
        expect(state.weatherSummary, contains('22'));
        expect(state.weatherSummary, contains('Sunny'));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'app launch with planned trip transitioning to ongoing → detects and activates',
      build: () {
        final now = DateTime.now();
        final plannedTrip = makeTrip(
          id: 'transition-trip',
          status: TripStatus.planned,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: now.add(const Duration(days: 3)),
        );
        final ongoingTrip = plannedTrip.copyWith(status: TripStatus.ongoing);

        // Initially no ongoing trips, but a planned trip that should transition
        stubUserAndTrips(planned: [plannedTrip]);

        // The transition API call
        when(
          () => mockTripRepo.updateTripStatus('transition-trip', 'ongoing'),
        ).thenAnswer((_) async => Success(ongoingTrip));

        when(
          () => mockActivityRepo.getActivities('transition-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockWeatherRepo.getWeather('transition-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        expect(state.activeTrip.id, 'transition-trip');
        // Notifications should be scheduled for the transitioned trip
        verify(
          () => mockScheduler.scheduleOngoingNotifications(any()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'app launch with no trips → HomeIdle emitted',
      build: () {
        stubUserAndTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeIdle>()],
    );

    blocTest<HomeBloc, HomeState>(
      'app launch with future trip only → HomeIdle, not active',
      build: () {
        final futureTrip = makeTrip(
          id: 'future-trip',
          status: TripStatus.planned,
          startDate: DateTime.now().add(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 35)),
        );

        stubUserAndTrips(planned: [futureTrip]);

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeIdle>()],
      verify: (bloc) {
        final state = bloc.state as HomeIdle;
        expect(state.nextTrip?.id, 'future-trip');
      },
    );

    blocTest<HomeBloc, HomeState>(
      'timeline shown: active trip loads activities for today',
      build: () {
        final now = DateTime.now();
        final trip = makeTrip(
          id: 'act-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 3)),
        );

        stubUserAndTrips(ongoing: [trip]);

        when(() => mockActivityRepo.getActivities('act-trip')).thenAnswer(
          (_) async => Success([
            makeActivity(
              id: 'a1',
              tripId: 'act-trip',
              title: 'Morning Walk',
              date: DateTime(now.year, now.month, now.day),
            ),
            makeActivity(
              id: 'a2',
              tripId: 'act-trip',
              title: 'Yesterday Lunch',
              date: now.subtract(const Duration(days: 1)),
              startTime: '12:00',
            ),
          ]),
        );
        when(
          () => mockWeatherRepo.getWeather('act-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        // allActivities should contain all activities
        expect(state.allActivities.length, 2);
        // todayActivities filtered to today only
        expect(state.todayActivities.length, 1);
        expect(state.todayActivities.first.title, 'Morning Walk');
      },
    );
  });
}
