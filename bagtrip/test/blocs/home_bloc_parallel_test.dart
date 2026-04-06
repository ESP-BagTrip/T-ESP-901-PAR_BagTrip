import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;
  late MockAuthRepository mockAuthRepo;
  late MockActivityRepository mockActivityRepo;
  late MockConnectivityService mockConnectivityService;
  late MockWeatherRepository mockWeatherRepo;
  late MockTripNotificationScheduler mockScheduler;
  late MockPostTripDismissalStorage mockDismissalStorage;

  setUpAll(() {
    registerFallbackValue(makeTrip());
  });

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAuthRepo = MockAuthRepository();
    mockActivityRepo = MockActivityRepository();
    mockConnectivityService = MockConnectivityService();
    mockWeatherRepo = MockWeatherRepository();
    mockScheduler = MockTripNotificationScheduler();
    mockDismissalStorage = MockPostTripDismissalStorage();

    when(() => mockConnectivityService.isOnline).thenReturn(true);
    when(
      () => mockConnectivityService.onConnectivityChanged,
    ).thenAnswer((_) => const Stream<bool>.empty());
    when(
      () => mockWeatherRepo.getWeather(any()),
    ).thenAnswer((_) async => const Failure(NetworkError('not available')));
    when(
      () => mockScheduler.scheduleOngoingNotifications(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.schedulePackingReminder(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.scheduleCompletionReminder(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.cancelTripNotifications(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockDismissalStorage.wasDismissedRecently(any()),
    ).thenAnswer((_) async => false);
  });

  void stubTrips({
    PaginatedResponse<Trip>? ongoing,
    PaginatedResponse<Trip>? planned,
    PaginatedResponse<Trip>? completed,
  }) {
    when(
      () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(ongoing ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
    ).thenAnswer(
      (_) async =>
          Success(planned ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
    ).thenAnswer(
      (_) async => Success(
        completed ?? makePaginatedResponse<Trip>(items: [], total: 0),
      ),
    );
  }

  void stubUserSuccess() {
    when(
      () => mockAuthRepo.getCurrentUser(),
    ).thenAnswer((_) async => Success(makeUser()));
  }

  void stubActivities() {
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
  }

  HomeBloc buildBloc() => HomeBloc(
    tripRepository: mockTripRepo,
    authRepository: mockAuthRepo,
    activityRepository: mockActivityRepo,
    connectivityService: mockConnectivityService,
    weatherRepository: mockWeatherRepo,
    scheduler: mockScheduler,
    dismissalStorage: mockDismissalStorage,
  );

  group('HomeBloc parallel loading', () {
    blocTest<HomeBloc, HomeState>(
      'HomeActiveTrip contains user, activeTrip when ongoing trip exists',
      build: () {
        stubUserSuccess();
        final ongoingTrip = makeTrip(
          id: 'trip-ongoing-1',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        );
        stubTrips(
          ongoing: makePaginatedResponse(items: [ongoingTrip]),
          planned: makePaginatedResponse<Trip>(items: [], total: 5),
          completed: makePaginatedResponse<Trip>(items: [], total: 10),
        );
        stubActivities();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeActiveTrip>()
            .having((s) => s.user.email, 'user email', 'test@example.com')
            .having((s) => s.activeTrip.id, 'activeTrip.id', 'trip-ongoing-1'),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'all data fetched in parallel — each endpoint called exactly once',
      build: () {
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockAuthRepo.getCurrentUser()).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
        ).called(1);
        verifyNoMoreInteractions(mockTripRepo);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'HomeIdle is emitted when totalTrips is 0',
      build: () {
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeIdle>()],
    );

    blocTest<HomeBloc, HomeState>(
      'displayName returns first name from full name',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => Success(makeUser(fullName: 'Jean Pierre Dupont')),
        );
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeIdle>().having((s) => s.displayName, 'displayName', 'Jean'),
      ],
    );
  });

  group('HomeBloc HomeError state', () {
    blocTest<HomeBloc, HomeState>(
      'emits HomeError when auth fails with AuthenticationError',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => const Failure(AuthenticationError('Token expired')),
        );
        stubTrips();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>().having(
          (s) => s.error,
          'error',
          isA<AuthenticationError>(),
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits HomeError when all three trip endpoints fail',
      build: () {
        stubUserSuccess();
        when(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 5),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 5),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 5),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>().having((s) => s.error, 'error', isA<ServerError>()),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'non-auth user failure still loads with fallback user',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Failure(NetworkError('No connection')));
        stubTrips(ongoing: makePaginatedResponse<Trip>(items: [], total: 2));
        stubActivities();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeIdle>().having((s) => s.user.id, 'user.id (fallback)', ''),
      ],
    );
  });

  group('HomeBloc retry mechanism', () {
    blocTest<HomeBloc, HomeState>(
      'retry after HomeError recovers to loaded state',
      build: () {
        var callCount = 0;
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Failure(AuthenticationError('expired'));
          }
          return Success(makeUser());
        });
        stubTrips(planned: makePaginatedResponse(items: [makeTrip()]));
        stubActivities();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadHome());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(LoadHome());
      },
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
        isA<HomeLoading>(),
        isA<HomeIdle>().having(
          (s) => s.user.email,
          'user after retry',
          'test@example.com',
        ),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'multiple LoadHome events do not stack — last one wins',
      build: () {
        stubUserSuccess();
        stubTrips();
        return buildBloc();
      },
      act: (bloc) {
        bloc.add(LoadHome());
        bloc.add(LoadHome());
      },
      verify: (bloc) {
        expect(bloc.state, isA<HomeIdle>());
      },
    );
  });
}
