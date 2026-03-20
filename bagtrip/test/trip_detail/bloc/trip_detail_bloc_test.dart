import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_fixtures.dart';

void main() {
  late MockTripRepository mockTripRepo;
  late MockActivityRepository mockActivityRepo;
  late MockAccommodationRepository mockAccommodationRepo;
  late MockBaggageRepository mockBaggageRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockTransportRepository mockTransportRepo;
  late MockTripShareRepository mockTripShareRepo;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockAccommodationRepo = MockAccommodationRepository();
    mockBaggageRepo = MockBaggageRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockTransportRepo = MockTransportRepository();
    mockTripShareRepo = MockTripShareRepository();
  });

  void stubAllSuccess({Trip? trip}) {
    when(
      () => mockTripRepo.getTripById(any()),
    ).thenAnswer((_) async => Success(trip ?? makeTrip()));
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockTransportRepo.getManualFlights(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockAccommodationRepo.getByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockBaggageRepo.getByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockBudgetRepo.getBudgetSummary(any()),
    ).thenAnswer((_) async => Success(makeBudgetSummary()));
    when(
      () => mockTripShareRepo.getSharesByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
  }

  TripDetailBloc buildBloc() => TripDetailBloc(
    tripRepository: mockTripRepo,
    activityRepository: mockActivityRepo,
    accommodationRepository: mockAccommodationRepo,
    baggageRepository: mockBaggageRepo,
    budgetRepository: mockBudgetRepo,
    transportRepository: mockTransportRepo,
    tripShareRepository: mockTripShareRepo,
  );

  group('TripDetailBloc', () {
    // ── LoadTripDetail ─────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [Loading, Loaded] on successful load',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>()
            .having((s) => s.trip.id, 'trip.id', 'trip-1')
            .having((s) => s.completionPercentage, 'completion', 20),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'emits [Loading, Error] when trip fetch fails',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => const Failure(NotFoundError('not found')));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      expect: () => [isA<TripDetailLoading>(), isA<TripDetailError>()],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'emits Loaded with empty lists when optional fetches fail',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => Success(makeTrip()));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>()
            .having((s) => s.activities, 'activities', isEmpty)
            .having((s) => s.flights, 'flights', isEmpty)
            .having((s) => s.accommodations, 'accommodations', isEmpty)
            .having((s) => s.baggageItems, 'baggageItems', isEmpty)
            .having((s) => s.budgetSummary, 'budgetSummary', isNull)
            .having((s) => s.shares, 'shares', isEmpty),
      ],
    );

    // ── RefreshTripDetail ──────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'RefreshTripDetail does not emit Loading',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(RefreshTripDetail());
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        // Refresh emits Loaded directly, no Loading
        isA<TripDetailLoaded>(),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'RefreshTripDetail preserves selectedDayIndex and collapsedSections',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(SelectDay(dayIndex: 2));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(ToggleSection(sectionId: 'transports'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(RefreshTripDetail());
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.selectedDayIndex,
          'selectedDayIndex',
          2,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.collapsedSections.contains('transports'),
          'collapsedSections',
          true,
        ),
        isA<TripDetailLoaded>()
            .having((s) => s.selectedDayIndex, 'selectedDayIndex', 2)
            .having(
              (s) => s.collapsedSections.contains('transports'),
              'collapsedSections',
              true,
            ),
      ],
    );

    // ── SelectDay ──────────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'SelectDay updates selectedDayIndex in loaded state',
      build: () => buildBloc(),
      seed: () => TripDetailLoaded(
        trip: makeTrip(),
        activities: [],
        flights: [],
        accommodations: [],
        baggageItems: [],
        shares: [],
        completionPercentage: 20,
      ),
      act: (bloc) => bloc.add(SelectDay(dayIndex: 5)),
      expect: () => [
        isA<TripDetailLoaded>().having(
          (s) => s.selectedDayIndex,
          'selectedDayIndex',
          5,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'SelectDay is no-op when not in loaded state',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(SelectDay(dayIndex: 5)),
      expect: () => <TripDetailState>[],
    );

    // ── ToggleSection ──────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'ToggleSection adds then removes sectionId',
      build: () => buildBloc(),
      seed: () => TripDetailLoaded(
        trip: makeTrip(),
        activities: [],
        flights: [],
        accommodations: [],
        baggageItems: [],
        shares: [],
        completionPercentage: 20,
      ),
      act: (bloc) {
        bloc.add(ToggleSection(sectionId: 'activities'));
        bloc.add(ToggleSection(sectionId: 'activities'));
      },
      expect: () => [
        isA<TripDetailLoaded>().having(
          (s) => s.collapsedSections.contains('activities'),
          'collapsed',
          true,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.collapsedSections.contains('activities'),
          'collapsed',
          false,
        ),
      ],
    );

    // ── ValidateActivity ───────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'ValidateActivity performs optimistic update then API call',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => Success(makeTrip()));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeActivity()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(ValidateActivity(activityId: 'act-1'));
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        // Optimistic update
        isA<TripDetailLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockActivityRepo.updateActivity('trip-1', 'act-1', {
            'validation_status': 'VALIDATED',
          }),
        ).called(1);
      },
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'ValidateActivity rolls back on API failure',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => Success(makeTrip()));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(ValidateActivity(activityId: 'act-1'));
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>(),
        // Rollback
        isA<TripDetailLoaded>(),
      ],
    );

    // ── RejectActivity ─────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'RejectActivity removes activity optimistically and rolls back on failure',
      build: () {
        when(
          () => mockTripRepo.getTripById(any()),
        ).thenAnswer((_) async => Success(makeTrip()));
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Success([]));
        when(
          () => mockActivityRepo.deleteActivity(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(RejectActivity(activityId: 'act-1'));
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          0,
        ),
        // Rollback
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
      ],
    );

    // ── UpdateTripStatus ───────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripStatus refreshes after success',
      build: () {
        stubAllSuccess();
        when(() => mockTripRepo.updateTripStatus(any(), any())).thenAnswer(
          (_) async => Success(makeTrip(status: TripStatus.planned)),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(UpdateTripStatus(status: 'PLANNED'));
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        // After updateTripStatus succeeds → RefreshTripDetail
        isA<TripDetailLoaded>(),
      ],
    );

    // ── DeleteTrip ─────────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteTripDetail emits TripDetailDeleted',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.deleteTrip(any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(DeleteTripDetail());
      },
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailDeleted>(),
      ],
    );
  });
}
