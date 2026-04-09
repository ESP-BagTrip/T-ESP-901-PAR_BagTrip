import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
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
      () => mockScheduler.cancelTripNotifications(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.scheduleCompletionReminder(any()),
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

  group('Post-trip transition integration', () {
    blocTest<HomeBloc, HomeState>(
      'trip ended yesterday → HomeActiveTrip with pendingCompletionTrip set',
      build: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'ended-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );

        stubUserAndTrips(ongoing: [endedTrip]);

        // Dismissal storage: not recently dismissed
        when(
          () => mockDismissalStorage.wasDismissedRecently('ended-trip'),
        ).thenAnswer((_) async => false);

        when(
          () => mockActivityRepo.getActivities('ended-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockWeatherRepo.getWeather('ended-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        expect(state.pendingCompletionTrip, isNotNull);
        expect(state.pendingCompletionTrip!.id, 'ended-trip');
      },
    );

    blocTest<HomeBloc, HomeState>(
      'ConfirmTripCompletion → updates status, cancels notifications, refreshes',
      build: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'confirm-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );

        stubUserAndTrips(ongoing: [endedTrip]);

        when(
          () => mockDismissalStorage.wasDismissedRecently('confirm-trip'),
        ).thenAnswer((_) async => false);
        when(
          () => mockDismissalStorage.clearDismissal('confirm-trip'),
        ).thenAnswer((_) async {});
        when(
          () => mockTripRepo.updateTripStatus('confirm-trip', 'completed'),
        ).thenAnswer(
          (_) async =>
              Success(endedTrip.copyWith(status: TripStatus.completed)),
        );

        when(
          () => mockActivityRepo.getActivities('confirm-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockWeatherRepo.getWeather('confirm-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      seed: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'confirm-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );
        return HomeActiveTrip(
          user: makeUser(),
          activeTrip: endedTrip,
          pendingCompletionTrip: endedTrip,
        );
      },
      act: (bloc) => bloc.add(ConfirmTripCompletion(tripId: 'confirm-trip')),
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        verify(
          () => mockTripRepo.updateTripStatus('confirm-trip', 'completed'),
        ).called(1);
        verify(() => mockScheduler.cancelTripNotifications(any())).called(1);
        verify(
          () => mockDismissalStorage.clearDismissal('confirm-trip'),
        ).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'DismissTripCompletion → records dismissal, schedules reminder, refreshes',
      build: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'dismiss-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );

        stubUserAndTrips(ongoing: [endedTrip]);

        when(
          () => mockDismissalStorage.wasDismissedRecently('dismiss-trip'),
        ).thenAnswer((_) async => true);
        when(
          () => mockDismissalStorage.recordDismissal('dismiss-trip'),
        ).thenAnswer((_) async {});

        when(
          () => mockActivityRepo.getActivities('dismiss-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockWeatherRepo.getWeather('dismiss-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      seed: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'dismiss-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );
        return HomeActiveTrip(
          user: makeUser(),
          activeTrip: endedTrip,
          pendingCompletionTrip: endedTrip,
        );
      },
      act: (bloc) => bloc.add(DismissTripCompletion(tripId: 'dismiss-trip')),
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        verify(
          () => mockDismissalStorage.recordDismissal('dismiss-trip'),
        ).called(1);
        verify(() => mockScheduler.scheduleCompletionReminder(any())).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'recently dismissed trip → no pendingCompletionTrip',
      build: () {
        final now = DateTime.now();
        final endedTrip = makeTrip(
          id: 'dismissed-trip',
          status: TripStatus.ongoing,
          startDate: now.subtract(const Duration(days: 5)),
          endDate: now.subtract(const Duration(days: 1)),
        );

        stubUserAndTrips(ongoing: [endedTrip]);

        // Recently dismissed: skip it
        when(
          () => mockDismissalStorage.wasDismissedRecently('dismissed-trip'),
        ).thenAnswer((_) async => true);

        when(
          () => mockActivityRepo.getActivities('dismissed-trip'),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockWeatherRepo.getWeather('dismissed-trip'),
        ).thenAnswer((_) async => const Failure(NetworkError('no weather')));

        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<HomeLoading>(), isA<HomeActiveTrip>()],
      verify: (bloc) {
        final state = bloc.state as HomeActiveTrip;
        expect(state.pendingCompletionTrip, isNull);
      },
    );
  });
}
