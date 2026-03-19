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

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAuthRepo = MockAuthRepository();
  });

  void stubTrips({
    PaginatedResponse<Trip>? ongoing,
    PaginatedResponse<Trip>? planned,
    PaginatedResponse<Trip>? completed,
  }) {
    when(
      () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
    ).thenAnswer(
      (_) async =>
          Success(ongoing ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
    ).thenAnswer(
      (_) async =>
          Success(planned ?? makePaginatedResponse<Trip>(items: [], total: 0)),
    );
    when(
      () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
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

  group('HomeBloc parallel loading', () {
    blocTest<HomeBloc, HomeState>(
      'HomeLoaded contains user, nextTrip, daysUntilNextTrip, and totalTrips',
      build: () {
        stubUserSuccess();
        final ongoingTrip = makeTrip(
          id: 'trip-ongoing-1',
          status: TripStatus.ongoing,
          startDate: DateTime.now().add(const Duration(days: 7)),
        );
        stubTrips(
          ongoing: makePaginatedResponse(items: [ongoingTrip]),
          planned: makePaginatedResponse<Trip>(items: [], total: 5),
          completed: makePaginatedResponse<Trip>(items: [], total: 10),
        );
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having((s) => s.user, 'user is present', isNotNull)
            .having((s) => s.user!.email, 'user email', 'test@example.com')
            .having((s) => s.nextTrip, 'nextTrip is present', isNotNull)
            .having((s) => s.nextTrip!.id, 'nextTrip.id', 'trip-ongoing-1')
            .having((s) => s.daysUntilNextTrip, 'daysUntilNextTrip', isNotNull)
            .having((s) => s.totalTrips, 'totalTrips', 16),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'all data fetched in parallel — each endpoint called exactly once',
      build: () {
        stubUserSuccess();
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      verify: (_) {
        verify(() => mockAuthRepo.getCurrentUser()).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
        ).called(1);
        verify(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
        ).called(1);
        verifyNoMoreInteractions(mockTripRepo);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'isNewUser is true when totalTrips is 0',
      build: () {
        stubUserSuccess();
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having((s) => s.totalTrips, 'totalTrips', 0)
            .having((s) => s.isNewUser, 'isNewUser', true)
            .having((s) => s.hasNextTrip, 'hasNextTrip', false),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'displayName returns first name from full name',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenAnswer(
          (_) async => Success(makeUser(fullName: 'Jean Pierre Dupont')),
        );
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having((s) => s.displayName, 'displayName', 'Jean'),
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
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
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
          () => mockTripRepo.getTripsPaginated(status: 'ongoing', limit: 1),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'planned', limit: 1),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        when(
          () => mockTripRepo.getTripsPaginated(status: 'completed', limit: 1),
        ).thenAnswer((_) async => const Failure(ServerError('Server down')));
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>().having((s) => s.error, 'error', isA<ServerError>()),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'non-auth user failure still loads with partial data',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Failure(NetworkError('No connection')));
        stubTrips(ongoing: makePaginatedResponse<Trip>(items: [], total: 2));
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) => bloc.add(LoadHome()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having((s) => s.user, 'user is null', isNull)
            .having((s) => s.totalTrips, 'totalTrips', 2),
      ],
    );
  });

  group('HomeBloc retry mechanism', () {
    blocTest<HomeBloc, HomeState>(
      'retry after HomeError recovers to HomeLoaded',
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
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
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
        isA<HomeLoaded>().having((s) => s.user, 'user after retry', isNotNull),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'multiple LoadHome events do not stack — last one wins',
      build: () {
        stubUserSuccess();
        stubTrips();
        return HomeBloc(
          tripRepository: mockTripRepo,
          authRepository: mockAuthRepo,
        );
      },
      act: (bloc) {
        bloc.add(LoadHome());
        bloc.add(LoadHome());
      },
      skip: 2, // skip first HomeLoading + HomeLoaded
      expect: () => [isA<HomeLoading>(), isA<HomeLoaded>()],
    );
  });
}
