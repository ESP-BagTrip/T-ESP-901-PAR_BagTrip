import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
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
      () => mockBudgetRepo.getBudgetItems(any()),
    ).thenAnswer((_) async => const Success([]));
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
      'emits [Loading, Loaded(deferred:false), Loaded(deferred:true)] on successful load',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>()
            .having((s) => s.trip.id, 'trip.id', 'trip-1')
            .having((s) => s.deferredLoaded, 'deferredLoaded', false),
        isA<TripDetailLoaded>()
            .having((s) => s.deferredLoaded, 'deferredLoaded', true)
            // Validation-aware formula: 0 items in every domain → 0%.
            .having((s) => s.completionPercentage, 'completion', 0),
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
          () => mockBudgetRepo.getBudgetItems(any()),
        ).thenAnswer((_) async => const Success([]));
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
          () => mockBudgetRepo.getBudgetItems(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        // Core load — activities failed → empty
        isA<TripDetailLoaded>()
            .having((s) => s.activities, 'activities', isEmpty)
            .having((s) => s.deferredLoaded, 'deferredLoaded', false),
        // Deferred load — all failed → empty
        isA<TripDetailLoaded>()
            .having((s) => s.flights, 'flights', isEmpty)
            .having((s) => s.accommodations, 'accommodations', isEmpty)
            .having((s) => s.baggageItems, 'baggageItems', isEmpty)
            .having((s) => s.budgetSummary, 'budgetSummary', isNull)
            .having((s) => s.shares, 'shares', isEmpty)
            .having((s) => s.deferredLoaded, 'deferredLoaded', true),
      ],
    );

    // ── LoadDeferredSections ──────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'LoadDeferredSections is no-op when deferredLoaded is already true',
      build: () => buildBloc(),
      seed: () => TripDetailLoaded(
        trip: makeTrip(),
        activities: [],
        flights: [],
        accommodations: [],
        baggageItems: [],
        shares: [],
        completionResult: makeCompletionResult(percentage: 20),
        deferredLoaded: true,
      ),
      act: (bloc) => bloc.add(LoadDeferredSections()),
      expect: () => <TripDetailState>[],
    );

    // ── RefreshTripDetail ──────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'RefreshTripDetail loads all data at once with deferredLoaded true',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(RefreshTripDetail());
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.deferredLoaded,
          'deferredLoaded',
          false,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.deferredLoaded,
          'deferredLoaded',
          true,
        ),
        // Refresh emits Loaded directly with deferredLoaded=true
        isA<TripDetailLoaded>().having(
          (s) => s.deferredLoaded,
          'deferredLoaded',
          true,
        ),
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
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(SelectDay(dayIndex: 2));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(ToggleSection(sectionId: 'transports'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(RefreshTripDetail());
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
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
        completionResult: makeCompletionResult(percentage: 20),
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
        completionResult: makeCompletionResult(percentage: 20),
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
        stubAllSuccess();
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeActivity()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(ValidateActivity(activityId: 'act-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        isA<TripDetailLoaded>(),
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
        stubAllSuccess();
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(ValidateActivity(activityId: 'act-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>(),
        // Rollback with operationError
        isA<TripDetailLoaded>(),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── RejectActivity ─────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'RejectActivity removes activity optimistically and rolls back on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(
          () => mockActivityRepo.deleteActivity(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(RejectActivity(activityId: 'act-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        isA<TripDetailLoaded>(),
        // Optimistic removal
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          0,
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
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
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripStatus(status: 'PLANNED'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // After updateTripStatus succeeds → RefreshTripDetail
        isA<TripDetailLoaded>(),
      ],
    );

    // ── UpdateTripTitle ────────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripTitle performs optimistic update then API call',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTrip(any(), any()),
        ).thenAnswer((_) async => Success(makeTrip(title: 'New Title')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripTitle(title: 'New Title'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>().having(
          (s) => s.trip.title,
          'trip.title',
          'New Title',
        ),
      ],
      verify: (_) {
        verify(
          () => mockTripRepo.updateTrip('trip-1', {'title': 'New Title'}),
        ).called(1);
      },
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripTitle rolls back on API failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTrip(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripTitle(title: 'New Title'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.trip.title,
          'trip.title',
          'Paris Trip',
        ),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>().having(
          (s) => s.trip.title,
          'trip.title',
          'New Title',
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.trip.title,
          'trip.title',
          'Paris Trip',
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── UpdateTripDates ──────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripDates performs optimistic update and recomputes completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTrip(any(), any()),
        ).thenAnswer((_) async => Success(makeTrip()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateTripDates(
            startDate: DateTime(2024, 7),
            endDate: DateTime(2024, 7, 10),
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update with new dates
        isA<TripDetailLoaded>()
            .having(
              (s) => s.trip.startDate,
              'trip.startDate',
              DateTime(2024, 7),
            )
            .having(
              (s) => s.trip.endDate,
              'trip.endDate',
              DateTime(2024, 7, 10),
            ),
      ],
      verify: (_) {
        verify(() => mockTripRepo.updateTrip('trip-1', any())).called(1);
      },
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripDates rolls back on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTrip(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('timeout')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateTripDates(
            startDate: DateTime(2024, 7),
            endDate: DateTime(2024, 7, 10),
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic
        isA<TripDetailLoaded>().having(
          (s) => s.trip.startDate,
          'trip.startDate',
          DateTime(2024, 7),
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.trip.startDate,
          'trip.startDate',
          DateTime(2024, 6),
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── UpdateTripTravelers ──────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripTravelers performs optimistic update and refreshes on success',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTrip(any(), any()),
        ).thenAnswer((_) async => Success(makeTrip(nbTravelers: 5)));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripTravelers(nbTravelers: 5));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>().having(
          (s) => s.trip.nbTravelers,
          'trip.nbTravelers',
          5,
        ),
        // RefreshTripDetail emits new Loaded
        isA<TripDetailLoaded>(),
      ],
    );

    // ── UpdateTripStatus validation ──────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripStatus PLANNED without destination emits validationError',
      build: () {
        stubAllSuccess(trip: makeTrip(destinationName: null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripStatus(status: 'PLANNED'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // validationError emitted
        isA<TripDetailLoaded>().having(
          (s) => s.validationError,
          'validationError',
          'finalize_conditions_not_met',
        ),
        // validationError cleared
        isA<TripDetailLoaded>().having(
          (s) => s.validationError,
          'validationError',
          isNull,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripStatus PLANNED without dates emits validationError',
      build: () {
        stubAllSuccess(
          trip: const Trip(id: 'trip-1', destinationName: 'Paris'),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripStatus(status: 'PLANNED'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // validationError emitted
        isA<TripDetailLoaded>().having(
          (s) => s.validationError,
          'validationError',
          'finalize_conditions_not_met',
        ),
        // validationError cleared
        isA<TripDetailLoaded>().having(
          (s) => s.validationError,
          'validationError',
          isNull,
        ),
      ],
    );

    // ── AddFlightToDetail ────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'AddFlightToDetail appends flight to loaded state',
      build: () => buildBloc(),
      seed: () => TripDetailLoaded(
        trip: makeTrip(),
        activities: [],
        flights: [],
        accommodations: [],
        baggageItems: [],
        shares: [],
        completionResult: makeCompletionResult(percentage: 20),
      ),
      act: (bloc) => bloc.add(AddFlightToDetail(flight: makeManualFlight())),
      expect: () => [
        isA<TripDetailLoaded>()
            .having((s) => s.flights.length, 'flights.length', 1)
            .having(
              (s) => s.flights.first.flightNumber,
              'flightNumber',
              'AF123',
            )
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.flights)
                  .isComplete,
              'flights segment',
              true,
            ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'AddFlightToDetail is no-op when not in loaded state',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(AddFlightToDetail(flight: makeManualFlight())),
      expect: () => <TripDetailState>[],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripStatus PLANNED with destination and dates calls API',
      build: () {
        stubAllSuccess();
        when(() => mockTripRepo.updateTripStatus(any(), any())).thenAnswer(
          (_) async => Success(makeTrip(status: TripStatus.planned)),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripStatus(status: 'PLANNED'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // After updateTripStatus succeeds → RefreshTripDetail
        isA<TripDetailLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockTripRepo.updateTripStatus('trip-1', 'PLANNED'),
        ).called(1);
      },
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
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteTripDetail());
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailDeleted>(),
      ],
    );

    // ── BatchValidateActivitiesFromDetail ─────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'BatchValidateActivitiesFromDetail optimistic validation of multiple activities',
      build: () {
        stubAllSuccess();
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async => Success([
            makeActivity(validationStatus: ValidationStatus.suggested),
            makeActivity(
              id: 'act-2',
              title: 'Louvre Museum',
              validationStatus: ValidationStatus.suggested,
            ),
          ]),
        );
        when(
          () => mockActivityRepo.batchUpdateActivities(any(), any(), any()),
        ).thenAnswer(
          (_) async => Success([
            makeActivity(),
            makeActivity(id: 'act-2', title: 'Louvre Museum'),
          ]),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          BatchValidateActivitiesFromDetail(activityIds: ['act-1', 'act-2']),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update — both activities validated
        isA<TripDetailLoaded>().having(
          (s) => s.activities.every(
            (a) => a.validationStatus == ValidationStatus.validated,
          ),
          'all validated',
          true,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'BatchValidateActivitiesFromDetail rolls back on API failure',
      build: () {
        stubAllSuccess();
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async => Success([
            makeActivity(validationStatus: ValidationStatus.suggested),
            makeActivity(
              id: 'act-2',
              title: 'Louvre Museum',
              validationStatus: ValidationStatus.suggested,
            ),
          ]),
        );
        when(
          () => mockActivityRepo.batchUpdateActivities(any(), any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          BatchValidateActivitiesFromDetail(activityIds: ['act-1', 'act-2']),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>(),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.activities.every(
            (a) => a.validationStatus == ValidationStatus.suggested,
          ),
          'all suggested',
          true,
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── CreateActivityFromDetail ──────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateActivityFromDetail appends new activity',
      build: () {
        stubAllSuccess();
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        when(() => mockActivityRepo.createActivity(any(), any())).thenAnswer(
          (_) async => Success(makeActivity(id: 'act-new', title: 'New')),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateActivityFromDetail(data: {'title': 'New'}));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          1,
        ),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.activities.length,
          'activities.length',
          2,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateActivityFromDetail is no-op when not loaded',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(CreateActivityFromDetail(data: {'title': 'X'})),
      expect: () => <TripDetailState>[],
    );

    // ── MoveActivityToDay ─────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'MoveActivityToDay performs optimistic date update',
      build: () {
        stubAllSuccess(
          trip: makeTrip(
            startDate: DateTime(2024, 6),
            endDate: DateTime(2024, 6, 7),
          ),
        );
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async => Success([makeActivity(date: DateTime(2024, 6))]),
        );
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer(
          (_) async => Success(makeActivity(date: DateTime(2024, 6, 3))),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(MoveActivityToDay(activityId: 'act-1', targetDayIndex: 2));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update — date changed to day index 2
        isA<TripDetailLoaded>().having(
          (s) => s.activities.first.date,
          'activity.date',
          DateTime(2024, 6, 3),
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'MoveActivityToDay rolls back on failure',
      build: () {
        stubAllSuccess(
          trip: makeTrip(
            startDate: DateTime(2024, 6),
            endDate: DateTime(2024, 6, 7),
          ),
        );
        when(() => mockActivityRepo.getActivities(any())).thenAnswer(
          (_) async => Success([makeActivity(date: DateTime(2024, 6))]),
        );
        when(
          () => mockActivityRepo.updateActivity(any(), any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(MoveActivityToDay(activityId: 'act-1', targetDayIndex: 2));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update
        isA<TripDetailLoaded>().having(
          (s) => s.activities.first.date,
          'activity.date',
          DateTime(2024, 6, 3),
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.activities.first.date,
          'activity.date',
          DateTime(2024, 6),
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'MoveActivityToDay is no-op when trip has no startDate',
      build: () {
        stubAllSuccess(
          trip: const Trip(id: 'trip-1', destinationName: 'Paris'),
        );
        when(
          () => mockActivityRepo.getActivities(any()),
        ).thenAnswer((_) async => Success([makeActivity()]));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(MoveActivityToDay(activityId: 'act-1', targetDayIndex: 2));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // No additional emissions — no-op
      ],
    );

    // ── SuggestActivitiesForDay ────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'SuggestActivitiesForDay sets suggestingForDay then populates daySuggestions',
      build: () {
        stubAllSuccess();
        when(
          () =>
              mockActivityRepo.suggestActivities(any(), day: any(named: 'day')),
        ).thenAnswer(
          (_) async => const Success([
            {'title': 'Suggested'},
          ]),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(SuggestActivitiesForDay(dayNumber: 1));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // suggestingForDay set
        isA<TripDetailLoaded>().having(
          (s) => s.suggestingForDay,
          'suggestingForDay',
          1,
        ),
        // daySuggestions populated, suggestingForDay cleared
        isA<TripDetailLoaded>()
            .having((s) => s.daySuggestions?.length, 'daySuggestions.length', 1)
            .having((s) => s.suggestingForDay, 'suggestingForDay', isNull)
            .having((s) => s.suggestionsForDay, 'suggestionsForDay', 1),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'SuggestActivitiesForDay clears suggestingForDay on failure',
      build: () {
        stubAllSuccess();
        when(
          () =>
              mockActivityRepo.suggestActivities(any(), day: any(named: 'day')),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(SuggestActivitiesForDay(dayNumber: 1));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // suggestingForDay set
        isA<TripDetailLoaded>().having(
          (s) => s.suggestingForDay,
          'suggestingForDay',
          1,
        ),
        // suggestingForDay cleared on failure
        isA<TripDetailLoaded>().having(
          (s) => s.suggestingForDay,
          'suggestingForDay',
          isNull,
        ),
      ],
    );

    // ── ClearDaySuggestions ────────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'ClearDaySuggestions clears daySuggestions',
      build: () => buildBloc(),
      seed: () => TripDetailLoaded(
        trip: makeTrip(),
        activities: [],
        flights: [],
        accommodations: [],
        baggageItems: [],
        shares: [],
        completionResult: makeCompletionResult(percentage: 20),
        daySuggestions: const [
          {'title': 'X'},
        ],
        suggestionsForDay: 1,
      ),
      act: (bloc) => bloc.add(ClearDaySuggestions()),
      expect: () => [
        isA<TripDetailLoaded>()
            .having((s) => s.daySuggestions, 'daySuggestions', isNull)
            .having((s) => s.suggestionsForDay, 'suggestionsForDay', isNull),
      ],
    );

    // ── CreateBudgetItemFromDetail ─────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateBudgetItemFromDetail optimistic budget summary update',
      build: () {
        stubAllSuccess();
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => Success(makeBudgetItem()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          CreateBudgetItemFromDetail(data: {'amount': 100, 'label': 'Taxi'}),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update — totalSpent increased by 100
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          500,
        ),
        // Refresh after success
        isA<TripDetailLoaded>(),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateBudgetItemFromDetail DANGER alertLevel when >=100%',
      build: () {
        stubAllSuccess();
        when(() => mockBudgetRepo.getBudgetSummary(any())).thenAnswer(
          (_) async => Success(
            makeBudgetSummary(
              totalSpent: 950,
              remaining: 50,
              percentConsumed: 95,
            ),
          ),
        );
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => Success(makeBudgetItem()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          CreateBudgetItemFromDetail(data: {'amount': 100, 'label': 'Taxi'}),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update — 1050/1000 = 105% → DANGER
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.alertLevel,
          'alertLevel',
          'DANGER',
        ),
        // Refresh after success
        isA<TripDetailLoaded>(),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateBudgetItemFromDetail WARNING alertLevel when >=80%',
      build: () {
        stubAllSuccess();
        when(() => mockBudgetRepo.getBudgetSummary(any())).thenAnswer(
          (_) async => Success(
            makeBudgetSummary(
              totalSpent: 700,
              remaining: 300,
              percentConsumed: 70,
            ),
          ),
        );
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => Success(makeBudgetItem()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          CreateBudgetItemFromDetail(data: {'amount': 150, 'label': 'Taxi'}),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Optimistic update — 850/1000 = 85% → WARNING
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.alertLevel,
          'alertLevel',
          'WARNING',
        ),
        // Refresh after success
        isA<TripDetailLoaded>(),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateBudgetItemFromDetail rolls back on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          CreateBudgetItemFromDetail(data: {'amount': 100, 'label': 'Taxi'}),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          isNull,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          400,
        ),
        // Optimistic update
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          500,
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          400,
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── ToggleBaggagePackedFromDetail ──────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'ToggleBaggagePackedFromDetail toggles isPacked optimistically',
      build: () {
        stubAllSuccess();
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem()]));
        when(
          () => mockBaggageRepo.updateBaggageItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeBaggageItem(isPacked: true)));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(ToggleBaggagePackedFromDetail(baggageItemId: 'bag-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.isPacked,
          'isPacked',
          false,
        ),
        // Optimistic toggle
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.isPacked,
          'isPacked',
          true,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'ToggleBaggagePackedFromDetail rolls back on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem()]));
        when(
          () => mockBaggageRepo.updateBaggageItem(any(), any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(ToggleBaggagePackedFromDetail(baggageItemId: 'bag-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.isPacked,
          'isPacked',
          false,
        ),
        // Optimistic toggle
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.isPacked,
          'isPacked',
          true,
        ),
        // Rollback with operationError
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.isPacked,
          'isPacked',
          false,
        ),
        // Rollback cleared
        isA<TripDetailLoaded>(),
      ],
    );

    // ── DeleteFlightFromDetail ─────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteFlightFromDetail removes flight and updates completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => Success([makeManualFlight()]));
        when(
          () => mockTransportRepo.deleteManualFlight(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteFlightFromDetail(flightId: 'flight-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.flights.length,
          'flights.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>()
            .having((s) => s.flights, 'flights', isEmpty)
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.flights)
                  .isComplete,
              'flights segment',
              false,
            ),
      ],
    );

    // ── DeleteAccommodationFromDetail ──────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteAccommodationFromDetail removes accommodation and updates completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockAccommodationRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeAccommodation()]));
        when(
          () => mockAccommodationRepo.deleteAccommodation(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteAccommodationFromDetail(accommodationId: 'acc-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.accommodations.length,
          'accommodations.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>()
            .having((s) => s.accommodations, 'accommodations', isEmpty)
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.accommodation)
                  .isComplete,
              'accommodation segment',
              false,
            ),
      ],
    );

    // ── DeleteBaggageItemFromDetail ────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteBaggageItemFromDetail removes item and updates completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem()]));
        when(
          () => mockBaggageRepo.deleteBaggageItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteBaggageItemFromDetail(baggageItemId: 'bag-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.length,
          'baggageItems.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>()
            .having((s) => s.baggageItems, 'baggageItems', isEmpty)
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.baggage)
                  .isComplete,
              'baggage segment',
              false,
            ),
      ],
    );

    // ── DeleteShareFromDetail ──────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteShareFromDetail removes share optimistically',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripShareRepo.getSharesByTrip(any()),
        ).thenAnswer((_) async => Success([makeTripShare()]));
        when(
          () => mockTripShareRepo.deleteShare(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteShareFromDetail(shareId: 'share-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.shares.length,
          'shares.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>().having((s) => s.shares, 'shares', isEmpty),
      ],
    );

    // ── CreateFlightFromDetail ─────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateFlightFromDetail appends new flight on success',
      build: () {
        stubAllSuccess();
        when(
          () => mockTransportRepo.createManualFlight(any(), any()),
        ).thenAnswer((_) async => Success(makeManualFlight()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateFlightFromDetail(data: {'flightNumber': 'AF123'}));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>()
            .having((s) => s.flights.length, 'flights.length', 1)
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.flights)
                  .isComplete,
              'flights segment',
              true,
            ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateFlightFromDetail surfaces operationError on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockTransportRepo.createManualFlight(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateFlightFromDetail(data: {'flightNumber': 'AF123'}));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // operationError then cleared
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isNotNull,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isNull,
        ),
      ],
    );

    // ── UpdateFlightFromDetail ─────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateFlightFromDetail replaces flight in place',
      build: () {
        stubAllSuccess();
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => Success([makeManualFlight()]));
        when(
          () => mockTransportRepo.updateManualFlight(any(), any(), any()),
        ).thenAnswer(
          (_) async => Success(makeManualFlight(flightNumber: 'LH456')),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateFlightFromDetail(
            flightId: 'flight-1',
            data: {'flightNumber': 'LH456'},
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.flights.first.flightNumber,
          'flightNumber',
          'LH456',
        ),
      ],
    );

    // ── CreateAccommodationFromDetail ──────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateAccommodationFromDetail appends and updates completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockAccommodationRepo.createAccommodation(
            any(),
            name: any(named: 'name'),
            address: any(named: 'address'),
            checkIn: any(named: 'checkIn'),
            checkOut: any(named: 'checkOut'),
            pricePerNight: any(named: 'pricePerNight'),
            currency: any(named: 'currency'),
            bookingReference: any(named: 'bookingReference'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Success(makeAccommodation()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateAccommodationFromDetail(data: {'name': 'Hotel'}));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>()
            .having((s) => s.accommodations.length, 'accommodations.length', 1)
            .having(
              (s) => s.completionResult
                  .segment(CompletionSegmentType.accommodation)
                  .isComplete,
              'accommodation segment',
              true,
            ),
      ],
    );

    // ── UpdateAccommodationFromDetail ──────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateAccommodationFromDetail replaces accommodation in place',
      build: () {
        stubAllSuccess();
        when(() => mockAccommodationRepo.getByTrip(any())).thenAnswer(
          (_) async => Success([makeAccommodation(name: 'Old Hotel')]),
        );
        when(
          () => mockAccommodationRepo.updateAccommodation(any(), any(), any()),
        ).thenAnswer(
          (_) async => Success(makeAccommodation(name: 'New Hotel')),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateAccommodationFromDetail(
            accommodationId: 'acc-1',
            data: {'name': 'New Hotel'},
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.accommodations.first.name,
          'name',
          'New Hotel',
        ),
      ],
    );

    // ── CreateBaggageItemFromDetail ────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateBaggageItemFromDetail appends and updates completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockBaggageRepo.createBaggageItem(
            any(),
            name: any(named: 'name'),
            quantity: any(named: 'quantity'),
            isPacked: any(named: 'isPacked'),
            category: any(named: 'category'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer((_) async => Success(makeBaggageItem(isPacked: true)));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateBaggageItemFromDetail(data: {'name': 'Passport'}));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.length,
          'baggageItems.length',
          1,
        ),
      ],
    );

    // ── UpdateBaggageItemFromDetail ────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateBaggageItemFromDetail replaces item in place',
      build: () {
        stubAllSuccess();
        when(
          () => mockBaggageRepo.getByTrip(any()),
        ).thenAnswer((_) async => Success([makeBaggageItem(name: 'Old')]));
        when(
          () => mockBaggageRepo.updateBaggageItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeBaggageItem(name: 'New')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateBaggageItemFromDetail(
            baggageItemId: 'bag-1',
            data: {'name': 'New'},
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.baggageItems.first.name,
          'name',
          'New',
        ),
      ],
    );

    // ── UpdateBudgetItemFromDetail ─────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateBudgetItemFromDetail replaces item and refreshes summary',
      build: () {
        stubAllSuccess();
        when(() => mockBudgetRepo.getBudgetItems(any())).thenAnswer(
          (_) async => Success([makeBudgetItem(label: 'Taxi', amount: 30)]),
        );
        when(
          () => mockBudgetRepo.updateBudgetItem(any(), any(), any()),
        ).thenAnswer(
          (_) async => Success(makeBudgetItem(label: 'Uber', amount: 40)),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateBudgetItemFromDetail(
            itemId: 'budget-1',
            data: {'label': 'Uber', 'amount': 40},
          ),
        );
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        // Replaced in place
        isA<TripDetailLoaded>().having(
          (s) => s.budgetItems.first.label,
          'label',
          'Uber',
        ),
        // RefreshBudgetSummary emits fresh state
        isA<TripDetailLoaded>(),
      ],
    );

    // ── DeleteBudgetItemFromDetail ─────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'DeleteBudgetItemFromDetail removes optimistically and refreshes',
      build: () {
        stubAllSuccess();
        when(
          () => mockBudgetRepo.getBudgetItems(any()),
        ).thenAnswer((_) async => Success([makeBudgetItem()]));
        when(
          () => mockBudgetRepo.deleteBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(DeleteBudgetItemFromDetail(itemId: 'budget-1'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.budgetItems.length,
          'budgetItems.length',
          1,
        ),
        // Optimistic removal
        isA<TripDetailLoaded>().having(
          (s) => s.budgetItems,
          'budgetItems',
          isEmpty,
        ),
        // RefreshBudgetSummary emits fresh state
        isA<TripDetailLoaded>(),
      ],
    );

    // ── RefreshBudgetSummaryFromDetail ─────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'RefreshBudgetSummaryFromDetail re-fetches summary + items only',
      build: () {
        stubAllSuccess();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        // Override for the refresh call
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary(totalSpent: 999)));
        bloc.add(RefreshBudgetSummaryFromDetail());
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.budgetSummary?.totalSpent,
          'totalSpent',
          999,
        ),
      ],
    );

    // ── CreateShareFromDetail ──────────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateShareFromDetail appends new share on success',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripShareRepo.createShare(
            any(),
            email: any(named: 'email'),
            role: any(named: 'role'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => Success(makeTripShare()));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateShareFromDetail(email: 'a@b.com', role: 'VIEWER'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.shares.length,
          'shares.length',
          1,
        ),
      ],
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'CreateShareFromDetail surfaces operationError on failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripShareRepo.createShare(
            any(),
            email: any(named: 'email'),
            role: any(named: 'role'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(CreateShareFromDetail(email: 'a@b.com', role: 'VIEWER'));
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TripDetailLoading>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>(),
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isNotNull,
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isNull,
        ),
      ],
    );

    // ── UpdateTripTrackingFromDetail ────────────────────────────────

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripTrackingFromDetail optimistically flips flightsTracking and '
      'recomputes completion',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTripTracking(
            any(),
            flightsTracking: any(named: 'flightsTracking'),
            accommodationsTracking: any(named: 'accommodationsTracking'),
          ),
        ).thenAnswer(
          (_) async => Success(makeTrip(flightsTracking: 'SKIPPED')),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(UpdateTripTrackingFromDetail(flightsTracking: 'SKIPPED'));
      },
      wait: const Duration(milliseconds: 300),
      skip: 2, // skip Loading + first Loaded(deferred:false)
      expect: () => [
        isA<TripDetailLoaded>().having(
          (s) => s.deferredLoaded,
          'deferredLoaded',
          true,
        ),
        isA<TripDetailLoaded>()
            .having((s) => s.trip.flightsTracking, 'flightsTracking', 'SKIPPED')
            // Segment counts as complete → completion jumps to 25 (one of
            // four segments satisfied).
            .having((s) => s.completionPercentage, 'completion', 25),
      ],
      verify: (_) {
        verify(
          () => mockTripRepo.updateTripTracking(
            'trip-1',
            flightsTracking: 'SKIPPED',
          ),
        ).called(1);
      },
    );

    blocTest<TripDetailBloc, TripDetailState>(
      'UpdateTripTrackingFromDetail surfaces operationError on API failure',
      build: () {
        stubAllSuccess();
        when(
          () => mockTripRepo.updateTripTracking(
            any(),
            flightsTracking: any(named: 'flightsTracking'),
            accommodationsTracking: any(named: 'accommodationsTracking'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(LoadTripDetail(tripId: 'trip-1'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        bloc.add(
          UpdateTripTrackingFromDetail(accommodationsTracking: 'SKIPPED'),
        );
      },
      wait: const Duration(milliseconds: 300),
      skip: 3, // Loading + two Loaded (deferred:false then true).
      expect: () => [
        isA<TripDetailLoaded>().having(
          (s) => s.trip.accommodationsTracking,
          'accommodationsTracking',
          'SKIPPED',
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isA<NetworkError>(),
        ),
        isA<TripDetailLoaded>().having(
          (s) => s.operationError,
          'operationError',
          isNull,
        ),
      ],
    );
  });
}
