import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/post_trip/bloc/post_trip_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;
  late MockActivityRepository mockActivityRepo;
  late MockBudgetRepository mockBudgetRepo;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockBudgetRepo = MockBudgetRepository();
  });

  group('PostTripBloc', () {
    blocTest<PostTripBloc, PostTripState>(
      'emits [PostTripLoading, PostTripLoaded] with correct stats',
      build: () {
        when(() => mockTripRepo.getTripById(any())).thenAnswer(
          (_) async => Success(
            makeTrip(
              status: TripStatus.completed,
              startDate: DateTime(2024, 6, 2),
              endDate: DateTime(2024, 6, 8),
            ),
          ),
        );
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async =>
              Success([makeActivity(id: 'a1'), makeActivity(id: 'a2')]),
        );
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary(totalSpent: 500)));
        return PostTripBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          budgetRepository: mockBudgetRepo,
        );
      },
      act: (bloc) => bloc.add(LoadPostTripStats(tripId: 'trip-1')),
      expect: () => [isA<PostTripLoading>(), isA<PostTripLoaded>()],
      verify: (bloc) {
        final state = bloc.state as PostTripLoaded;
        expect(state.totalDays, 7);
        expect(state.totalActivities, 2);
        expect(state.budgetSpent, 500);
        expect(state.budgetTotal, 1000);
        expect(state.destinationName, 'Paris');
      },
    );

    blocTest<PostTripBloc, PostTripState>(
      'trip with 0 activities has stats at 0',
      build: () {
        when(() => mockTripRepo.getTripById(any())).thenAnswer(
          (_) async => Success(makeTrip(status: TripStatus.completed)),
        );
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return PostTripBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          budgetRepository: mockBudgetRepo,
        );
      },
      act: (bloc) => bloc.add(LoadPostTripStats(tripId: 'trip-1')),
      expect: () => [isA<PostTripLoading>(), isA<PostTripLoaded>()],
      verify: (bloc) {
        final state = bloc.state as PostTripLoaded;
        expect(state.totalActivities, 0);
        expect(state.activitiesCompleted, 0);
        expect(state.budgetSpent, 0);
        expect(state.hasAiActivities, false);
      },
    );

    blocTest<PostTripBloc, PostTripState>(
      'trip without endDate has totalDays = 1',
      build: () {
        when(() => mockTripRepo.getTripById(any())).thenAnswer(
          (_) async => Success(
            makeTrip(status: TripStatus.completed).copyWith(endDate: null),
          ),
        );
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        return PostTripBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          budgetRepository: mockBudgetRepo,
        );
      },
      act: (bloc) => bloc.add(LoadPostTripStats(tripId: 'trip-1')),
      expect: () => [isA<PostTripLoading>(), isA<PostTripLoaded>()],
      verify: (bloc) {
        final state = bloc.state as PostTripLoaded;
        expect(state.totalDays, 1);
      },
    );

    blocTest<PostTripBloc, PostTripState>(
      'activitiesCompleted counts isDone, not isBooked',
      build: () {
        when(() => mockTripRepo.getTripById(any())).thenAnswer(
          (_) async => Success(makeTrip(status: TripStatus.completed)),
        );
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async => Success([
            makeActivity(id: 'a1', isDone: true),
            makeActivity(id: 'a2', isBooked: true),
            makeActivity(id: 'a3'),
          ]),
        );
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        return PostTripBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          budgetRepository: mockBudgetRepo,
        );
      },
      act: (bloc) => bloc.add(LoadPostTripStats(tripId: 'trip-1')),
      expect: () => [isA<PostTripLoading>(), isA<PostTripLoaded>()],
      verify: (bloc) {
        final state = bloc.state as PostTripLoaded;
        expect(state.activitiesCompleted, 1);
        expect(state.totalActivities, 3);
      },
    );

    blocTest<PostTripBloc, PostTripState>(
      'emits PostTripError when trip fetch fails',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        return PostTripBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          budgetRepository: mockBudgetRepo,
        );
      },
      act: (bloc) => bloc.add(LoadPostTripStats(tripId: 'trip-1')),
      expect: () => [isA<PostTripLoading>(), isA<PostTripError>()],
    );
  });
}
