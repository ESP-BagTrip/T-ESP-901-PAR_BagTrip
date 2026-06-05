import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/models/trip.dart';
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
  late MockConnectivityService mockConnectivityService;
  late MockPostTripDismissalStorage mockDismissalStorage;
  late MockOfflineWriteQueue mockOfflineWriteQueue;

  setUpAll(() {
    registerFallbackValue(makeTrip());
    registerFallbackValue(_FakePendingWriteOperation());
    registerFallbackValue((Map<String, dynamic> _) async => true);
  });

  setUp(() {
    mockHomeRepo = MockHomeRepository();
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockConnectivityService = MockConnectivityService();
    mockDismissalStorage = MockPostTripDismissalStorage();
    mockOfflineWriteQueue = MockOfflineWriteQueue();

    when(() => mockConnectivityService.isOnline).thenReturn(true);
    when(
      () => mockConnectivityService.onConnectivityChanged,
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

  void stubHome({
    List<Trip>? ongoing,
    List<Trip>? planned,
    List<Trip>? completed,
  }) {
    when(() => mockHomeRepo.getHome()).thenAnswer(
      (_) async => Success(
        makeHomeSummary(
          ongoingTrips: ongoing,
          plannedTrips: planned,
          completedTrips: completed,
        ),
      ),
    );
  }

  HomeBloc buildBloc() => HomeBloc(
    homeRepository: mockHomeRepo,
    tripRepository: mockTripRepo,
    activityRepository: mockActivityRepo,
    connectivityService: mockConnectivityService,
    dismissalStorage: mockDismissalStorage,
    offlineWriteQueue: mockOfflineWriteQueue,
  );

  group('HomeBloc aggregated loading', () {
    blocTest<HomeBloc, HomeState>(
      'HomeActiveTrip contains user, activeTrip when ongoing trip exists',
      build: () {
        final ongoingTrip = makeTrip(
          id: 'trip-ongoing-1',
          status: TripStatus.ongoing,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
        );
        stubHome(ongoing: [ongoingTrip]);
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
      'home data fetched via a single getHome() call',
      build: () {
        stubHome();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockHomeRepo.getHome()).called(1);
        verifyNoMoreInteractions(mockHomeRepo);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'HomeIdle is emitted when there are no trips',
      build: () {
        stubHome();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [isA<HomeLoading>(), isA<HomeIdle>()],
    );

    blocTest<HomeBloc, HomeState>(
      'displayName returns first name from full name',
      build: () {
        when(() => mockHomeRepo.getHome()).thenAnswer(
          (_) async => Success(
            makeHomeSummary(user: makeUser(fullName: 'Jean Pierre Dupont')),
          ),
        );
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
      'emits HomeError when /home fails with AuthenticationError',
      build: () {
        when(() => mockHomeRepo.getHome()).thenAnswer(
          (_) async => const Failure(AuthenticationError('Token expired')),
        );
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
      'emits HomeError when /home returns a server error',
      build: () {
        when(
          () => mockHomeRepo.getHome(),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>().having((s) => s.error, 'error', isA<ServerError>()),
      ],
    );
  });

  group('HomeBloc retry mechanism', () {
    blocTest<HomeBloc, HomeState>(
      'retry after HomeError recovers to loaded state',
      build: () {
        var callCount = 0;
        when(() => mockHomeRepo.getHome()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const Failure(AuthenticationError('expired'));
          }
          return Success(makeHomeSummary(plannedTrips: [makeTrip()]));
        });
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
        stubHome();
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
