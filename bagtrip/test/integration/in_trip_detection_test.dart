import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

class _FakePendingWriteOperation extends Fake
    implements PendingWriteOperation {}

void main() {
  late MockHomeRepository mockHomeRepo;
  late MockTripRepository mockTripRepo;
  late MockActivityRepository mockActivityRepo;
  late MockConnectivityService mockConnectivity;
  late MockPostTripDismissalStorage mockDismissalStorage;
  late MockOfflineWriteQueue mockOfflineWriteQueue;

  setUp(() {
    mockHomeRepo = MockHomeRepository();
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockConnectivity = MockConnectivityService();
    mockDismissalStorage = MockPostTripDismissalStorage();
    mockOfflineWriteQueue = MockOfflineWriteQueue();

    registerFallbackValue(makeTrip());
    registerFallbackValue(_FakePendingWriteOperation());
    registerFallbackValue((Map<String, dynamic> _) async => true);

    when(() => mockConnectivity.isOnline).thenReturn(true);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockDismissalStorage.wasDismissedRecently(any()),
    ).thenAnswer((_) async => false);
    when(
      () => mockOfflineWriteQueue.registerHandler(any(), any()),
    ).thenReturn(null);
    when(() => mockOfflineWriteQueue.enqueue(any())).thenAnswer((_) async {});
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
  });

  HomeBloc buildBloc() => HomeBloc(
    homeRepository: mockHomeRepo,
    tripRepository: mockTripRepo,
    activityRepository: mockActivityRepo,
    connectivityService: mockConnectivity,
    dismissalStorage: mockDismissalStorage,
    offlineWriteQueue: mockOfflineWriteQueue,
  );

  void stubHome({
    List<Trip> ongoing = const [],
    List<Trip> planned = const [],
    List<Trip> completed = const [],
    List<Activity> activeTripActivities = const [],
    WeatherSummary? activeTripWeather,
  }) {
    when(() => mockHomeRepo.getHome()).thenAnswer(
      (_) async => Success(
        makeHomeSummary(
          ongoingTrips: ongoing,
          plannedTrips: planned,
          completedTrips: completed,
          activeTripActivities: activeTripActivities,
          activeTripWeather: activeTripWeather,
        ),
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

        stubHome(
          ongoing: [tripStartingToday],
          activeTripWeather: const WeatherSummary(
            avgTempC: 22,
            description: 'Sunny',
          ),
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
        stubHome(planned: [plannedTrip]);

        // The transition API call
        when(
          () => mockTripRepo.updateTripStatus('transition-trip', 'ongoing'),
        ).thenAnswer((_) async => Success(ongoingTrip));

        when(
          () => mockActivityRepo.getActivities('transition-trip'),
        ).thenAnswer(
          (_) async => Success([
            makeActivity(
              id: 'a-transition',
              tripId: 'transition-trip',
              title: 'Museum visit',
              date: DateTime(now.year, now.month, now.day),
              startTime: '10:00',
            ),
          ]),
        );

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        expect(state.activeTrip.id, 'transition-trip');
        expect(state.allActivities, hasLength(1));
        expect(state.allActivities.first.title, 'Museum visit');
        verify(
          () => mockActivityRepo.getActivities('transition-trip'),
        ).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'app launch with no trips → HomeIdle emitted',
      build: () {
        stubHome();
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

        stubHome(planned: [futureTrip]);

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

        stubHome(
          ongoing: [trip],
          activeTripActivities: [
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
          ],
        );

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
