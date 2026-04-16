// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/mock_services.dart';

Trip _makeTrip() =>
    const Trip(id: 'trip-1', title: 'Barcelona', status: TripStatus.planned);

void main() {
  late MockTripRepository mockTripRepo;
  late MockAiRepository mockAiRepo;
  late MockAuthRepository mockAuthRepo;
  late MockPersonalizationStorage mockStorage;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockAiRepo = MockAiRepository();
    mockAuthRepo = MockAuthRepository();
    mockStorage = MockPersonalizationStorage();
  });

  PlanTripBloc buildBloc() => PlanTripBloc(
    tripRepository: mockTripRepo,
    aiRepository: mockAiRepo,
    authRepository: mockAuthRepo,
    personalizationStorage: mockStorage,
  );

  group('initial state', () {
    test('has correct defaults', () {
      final bloc = buildBloc();
      expect(bloc.state.currentStep, 0);
      expect(bloc.state.dateMode, DateMode.exact);
      expect(bloc.state.nbAdults, 1);
      expect(bloc.state.nbChildren, 0);
      expect(bloc.state.nbBabies, 0);
      expect(bloc.state.nbTravelers, 1);
      expect(bloc.state.isManualFlow, false);
      expect(bloc.state.searchResults, isEmpty);
      expect(bloc.state.aiSuggestions, isEmpty);
      bloc.close();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────────────

  group('navigation', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'NextStep increments currentStep',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.nextStep()),
      expect: () => [
        isA<PlanTripState>().having((s) => s.currentStep, 'step', 1),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'PreviousStep does not go below 0',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.previousStep()),
      expect: () => <PlanTripState>[],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'GoToStep sets specific step',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.goToStep(2)),
      expect: () => [
        isA<PlanTripState>().having((s) => s.currentStep, 'step', 2),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'GoToStep ignores out-of-bounds',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.goToStep(99)),
      expect: () => <PlanTripState>[],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'NextStep skips step 3 for manual flow',
      build: buildBloc,
      seed: () => const PlanTripState(currentStep: 2, isManualFlow: true),
      act: (bloc) => bloc.add(const PlanTripEvent.nextStep()),
      expect: () => [
        isA<PlanTripState>().having((s) => s.currentStep, 'step', 4),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'PreviousStep skips step 3 for manual flow',
      build: buildBloc,
      seed: () => const PlanTripState(currentStep: 4, isManualFlow: true),
      act: (bloc) => bloc.add(const PlanTripEvent.previousStep()),
      expect: () => [
        isA<PlanTripState>().having((s) => s.currentStep, 'step', 2),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'NextStep clears error',
      build: buildBloc,
      seed: () => const PlanTripState(error: UnknownError('some error')),
      act: (bloc) => bloc.add(const PlanTripEvent.nextStep()),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.error, 'error', isNull)
            .having((s) => s.currentStep, 'step', 1),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 0 — Dates
  // ─────────────────────────────────────────────────────────────────────────

  group('dates', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'SetDateMode updates mode',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const PlanTripEvent.setDateMode(DateMode.flexible)),
      expect: () => [
        isA<PlanTripState>().having(
          (s) => s.dateMode,
          'dateMode',
          DateMode.flexible,
        ),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'SetExactDates stores start and end',
      build: buildBloc,
      act: (bloc) => bloc.add(
        PlanTripEvent.setExactDates(DateTime(2026, 4), DateTime(2026, 4, 8)),
      ),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.startDate, 'start', DateTime(2026, 4))
            .having((s) => s.endDate, 'end', DateTime(2026, 4, 8)),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'SetMonthPreference stores month and year',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.setMonthPreference(6, 2026)),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.preferredMonth, 'month', 6)
            .having((s) => s.preferredYear, 'year', 2026),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'SetFlexibleDuration stores preset',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PlanTripEvent.setFlexibleDuration(DurationPreset.oneWeek),
      ),
      expect: () => [
        isA<PlanTripState>().having(
          (s) => s.flexibleDuration,
          'duration',
          DurationPreset.oneWeek,
        ),
      ],
    );

    test('areDatesValid — exact mode requires both dates', () {
      const state = PlanTripState();
      expect(state.areDatesValid, false);

      final withDates = state.copyWith(
        startDate: DateTime(2026, 4),
        endDate: DateTime(2026, 4, 8),
      );
      expect(withDates.areDatesValid, true);

      final reversed = state.copyWith(
        startDate: DateTime(2026, 4, 8),
        endDate: DateTime(2026, 4),
      );
      expect(reversed.areDatesValid, false);
    });

    test('areDatesValid — month mode requires month + year', () {
      const state = PlanTripState(dateMode: DateMode.month);
      expect(state.areDatesValid, false);

      final withMonth = state.copyWith(preferredMonth: 6, preferredYear: 2026);
      expect(withMonth.areDatesValid, true);
    });

    test('areDatesValid — flexible mode requires duration preset', () {
      const state = PlanTripState(dateMode: DateMode.flexible);
      expect(state.areDatesValid, false);

      final withPreset = state.copyWith(
        flexibleDuration: DurationPreset.weekend,
      );
      expect(withPreset.areDatesValid, true);
    });

    test('tripDurationDays from exact dates', () {
      final state = const PlanTripState().copyWith(
        startDate: DateTime(2026, 4),
        endDate: DateTime(2026, 4, 8),
      );
      expect(state.tripDurationDays, 7);
    });

    test('tripDurationDays from flexible preset', () {
      const state = PlanTripState(
        dateMode: DateMode.flexible,
        flexibleDuration: DurationPreset.twoWeeks,
      );
      expect(state.tripDurationDays, 14);
    });

    test('tripDurationDays null when nothing set', () {
      const state = PlanTripState();
      expect(state.tripDurationDays, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 1 — Travelers + Budget
  // ─────────────────────────────────────────────────────────────────────────

  group('travelers & budget', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'SetTravelerCounts updates adults',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.setTravelerCounts(adults: 3)),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.nbAdults, 'adults', 3)
            .having((s) => s.nbTravelers, 'total', 3),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'SetBudgetPreset updates preset',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const PlanTripEvent.setBudgetPreset(BudgetPreset.premium)),
      expect: () => [
        isA<PlanTripState>().having(
          (s) => s.budgetPreset,
          'preset',
          BudgetPreset.premium,
        ),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'SetBudgetPreset can be cleared to null',
      build: buildBloc,
      seed: () => const PlanTripState(budgetPreset: BudgetPreset.comfortable),
      act: (bloc) => bloc.add(const PlanTripEvent.setBudgetPreset(null)),
      expect: () => [
        isA<PlanTripState>().having((s) => s.budgetPreset, 'preset', isNull),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 — Destination Search
  // ─────────────────────────────────────────────────────────────────────────

  group('destination search', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'short query clears results',
      build: buildBloc,
      seed: () => const PlanTripState(
        searchResults: [LocationResult(name: 'Old', iataCode: 'OLD')],
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.searchDestination('P')),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.searchResults, 'results', isEmpty)
            .having((s) => s.isSearching, 'searching', false),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'successful search populates results from manual catalog',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.searchDestination('Paris')),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.isSearching, 'searching', false)
            .having((s) => s.searchResults.length, 'count', 1)
            .having((s) => s.searchResults.first.name, 'name', 'Paris')
            .having((s) => s.searchResults.first.iataCode, 'iata', 'PAR'),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'selectManualDestination sets destination and manual flow',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PlanTripEvent.selectManualDestination(
          LocationResult(
            name: 'Barcelona',
            iataCode: 'BCN',
            countryName: 'Spain',
          ),
        ),
      ),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.selectedManualDestination?.iataCode, 'iata', 'BCN')
            .having((s) => s.isManualFlow, 'manual', true)
            .having((s) => s.searchResults, 'cleared', isEmpty),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 — AI destination selection
  // ─────────────────────────────────────────────────────────────────────────

  group('AI destination', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'selectAiDestination sets destination and advances to step 3',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PlanTripEvent.selectAiDestination(
          AiDestination(city: 'Tokyo', country: 'Japan'),
        ),
      ),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.selectedAiDestination?.city, 'city', 'Tokyo')
            .having((s) => s.isManualFlow, 'manual', false)
            .having((s) => s.currentStep, 'step', 3),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 5 — Create Trip (manual)
  // ─────────────────────────────────────────────────────────────────────────

  group('create trip — manual flow', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'creates trip via TripRepository in manual flow',
      build: () {
        when(
          () => mockTripRepo.createTrip(
            title: any(named: 'title'),
            destinationName: any(named: 'destinationName'),
            destinationIata: any(named: 'destinationIata'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            nbTravelers: any(named: 'nbTravelers'),
          ),
        ).thenAnswer((_) async => Success(_makeTrip()));
        return buildBloc();
      },
      seed: () => PlanTripState(
        isManualFlow: true,
        selectedManualDestination: const LocationResult(
          name: 'Barcelona',
          iataCode: 'BCN',
          countryName: 'Spain',
        ),
        startDate: DateTime(2026, 5),
        endDate: DateTime(2026, 5, 8),
        nbAdults: 2,
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      expect: () => [
        isA<PlanTripState>().having((s) => s.isCreating, 'creating', true),
        isA<PlanTripState>()
            .having((s) => s.isCreating, 'creating', false)
            .having((s) => s.createdTripId, 'tripId', 'trip-1'),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // BackToProposals
  // ─────────────────────────────────────────────────────────────────────────

  group('backToProposals', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'resets generation state and goes to step 3 for AI flow',
      build: buildBloc,
      seed: () => const PlanTripState(currentStep: 5, generationProgress: 1.0),
      act: (bloc) => bloc.add(const PlanTripEvent.backToProposals()),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.currentStep, 'step', 3)
            .having((s) => s.generatedPlan, 'plan', isNull)
            .having((s) => s.generationProgress, 'progress', 0.0),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'goes to step 2 for manual flow',
      build: buildBloc,
      seed: () => const PlanTripState(currentStep: 5, isManualFlow: true),
      act: (bloc) => bloc.add(const PlanTripEvent.backToProposals()),
      expect: () => [
        isA<PlanTripState>().having((s) => s.currentStep, 'step', 2),
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Computed getters
  // ─────────────────────────────────────────────────────────────────────────

  group('computed getters', () {
    test('isDestinationValid with manual', () {
      const state = PlanTripState(
        selectedManualDestination: LocationResult(
          name: 'Test',
          iataCode: 'TST',
        ),
      );
      expect(state.isDestinationValid, true);
    });

    test('isDestinationValid with AI', () {
      const state = PlanTripState(
        selectedAiDestination: AiDestination(city: 'Tokyo', country: 'Japan'),
      );
      expect(state.isDestinationValid, true);
    });

    test('isDestinationValid false when empty', () {
      const state = PlanTripState();
      expect(state.isDestinationValid, false);
    });

    test('totalSteps for AI flow is 6', () {
      const state = PlanTripState();
      expect(state.totalSteps, 6);
    });

    test('totalSteps for manual flow is 5', () {
      const state = PlanTripState(isManualFlow: true);
      expect(state.totalSteps, 5);
    });

    test('nextStepAfterDestination for AI is 3', () {
      const state = PlanTripState();
      expect(state.nextStepAfterDestination, 3);
    });

    test('nextStepAfterDestination for manual is 4', () {
      const state = PlanTripState(isManualFlow: true);
      expect(state.nextStepAfterDestination, 4);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4 — SSE Stream Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  group('SSE stream lifecycle', () {
    const testUser = User(
      id: 'user-1',
      email: 'test@test.com',
      aiGenerationsRemaining: 5,
    );

    void stubForGeneration({
      required MockAuthRepository authRepo,
      required MockPersonalizationStorage storage,
      required MockAiRepository aiRepo,
      required StreamController<Map<String, dynamic>> controller,
    }) {
      when(
        () => authRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Success(testUser));
      when(() => storage.getTravelTypes(any())).thenAnswer((_) async => '');
      when(() => storage.getCompanions(any())).thenAnswer((_) async => '');
      when(() => storage.getConstraints(any())).thenAnswer((_) async => '');
      when(
        () => aiRepo.planTripStream(
          travelTypes: any(named: 'travelTypes'),
          budgetRange: any(named: 'budgetRange'),
          durationDays: any(named: 'durationDays'),
          companions: any(named: 'companions'),
          constraints: any(named: 'constraints'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          originCity: any(named: 'originCity'),
        ),
      ).thenAnswer((_) => controller.stream);
    }

    test('startGeneration assigns _sseSubscription via listen', () async {
      final controller = StreamController<Map<String, dynamic>>();
      stubForGeneration(
        authRepo: mockAuthRepo,
        storage: mockStorage,
        aiRepo: mockAiRepo,
        controller: controller,
      );

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());

      // Allow the bloc event handler to start
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Stream should be active — send an event to prove it
      controller.add({
        'event': 'progress',
        'data': {'message': 'Working...'},
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationMessage, 'Working...');

      // Close stream to let the handler complete
      await controller.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await bloc.close();
    });

    test('backToProposals cancels running SSE stream', () async {
      final controller = StreamController<Map<String, dynamic>>();
      stubForGeneration(
        authRepo: mockAuthRepo,
        storage: mockStorage,
        aiRepo: mockAiRepo,
        controller: controller,
      );

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Stream should be listening
      expect(controller.hasListener, isTrue);

      // Back to proposals should cancel the stream
      bloc.add(const PlanTripEvent.backToProposals());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.hasListener, isFalse);
      expect(bloc.state.generatedPlan, isNull);
      expect(bloc.state.generationProgress, 0.0);

      await controller.close();
      await bloc.close();
    });

    test('close() cancels running SSE stream', () async {
      final controller = StreamController<Map<String, dynamic>>();
      stubForGeneration(
        authRepo: mockAuthRepo,
        storage: mockStorage,
        aiRepo: mockAiRepo,
        controller: controller,
      );

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.hasListener, isTrue);

      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.hasListener, isFalse);
      await controller.close();
    });

    test('SSE stream error emits generationError', () async {
      final controller = StreamController<Map<String, dynamic>>();
      stubForGeneration(
        authRepo: mockAuthRepo,
        storage: mockStorage,
        aiRepo: mockAiRepo,
        controller: controller,
      );

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      controller.addError(Exception('SSE connection lost'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.generationError, isNotNull);

      await controller.close();
      await bloc.close();
    });

    test('retryGeneration cancels existing stream', () async {
      final controller1 = StreamController<Map<String, dynamic>>();
      final controller2 = StreamController<Map<String, dynamic>>();
      var callCount = 0;

      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Success(testUser));
      when(() => mockStorage.getTravelTypes(any())).thenAnswer((_) async => '');
      when(() => mockStorage.getCompanions(any())).thenAnswer((_) async => '');
      when(() => mockStorage.getConstraints(any())).thenAnswer((_) async => '');
      when(
        () => mockAiRepo.planTripStream(
          travelTypes: any(named: 'travelTypes'),
          budgetRange: any(named: 'budgetRange'),
          durationDays: any(named: 'durationDays'),
          companions: any(named: 'companions'),
          constraints: any(named: 'constraints'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          originCity: any(named: 'originCity'),
        ),
      ).thenAnswer((_) {
        callCount++;
        return callCount == 1 ? controller1.stream : controller2.stream;
      });

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller1.hasListener, isTrue);

      // Retry cancels the first stream and starts a new one
      bloc.add(const PlanTripEvent.retryGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(controller1.hasListener, isFalse);
      expect(controller2.hasListener, isTrue);

      await controller1.close();
      await controller2.close();
      await bloc.close();
    });

    test('quota exceeded short-circuits with generationError', () async {
      const outOfQuota = User(
        id: 'user-1',
        email: 'x@x',
        aiGenerationsRemaining: 0,
      );
      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Success(outOfQuota));

      final bloc = buildBloc();
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.generationError, 'AI generation quota exceeded');
      verifyNever(
        () => mockAiRepo.planTripStream(
          travelTypes: any(named: 'travelTypes'),
          budgetRange: any(named: 'budgetRange'),
          durationDays: any(named: 'durationDays'),
          companions: any(named: 'companions'),
          constraints: any(named: 'constraints'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          originCity: any(named: 'originCity'),
        ),
      );

      await bloc.close();
    });

    Future<PlanTripBloc> bootGeneratingBloc(
      StreamController<Map<String, dynamic>> controller, {
      PlanTripState? seedOverride,
    }) async {
      stubForGeneration(
        authRepo: mockAuthRepo,
        storage: mockStorage,
        aiRepo: mockAiRepo,
        controller: controller,
      );
      final bloc = buildBloc();
      if (seedOverride != null) bloc.emit(seedOverride);
      bloc.add(const PlanTripEvent.startGeneration());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return bloc;
    }

    test('progress event updates generationMessage', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);

      controller.add({
        'event': 'progress',
        'data': {'message': 'Phase 1'},
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationMessage, 'Phase 1');

      await controller.close();
      await bloc.close();
    });

    test('destinations → activities step cascade sets progress 0.2', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);

      controller.add({'event': 'destinations', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationProgress, 0.2);

      await controller.close();
      await bloc.close();
    });

    test('activities event advances progress to 0.4', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'activities', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationProgress, 0.4);
      await controller.close();
      await bloc.close();
    });

    test('accommodations event advances progress to 0.6', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'accommodations', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationProgress, 0.6);
      await controller.close();
      await bloc.close();
    });

    test('baggage event advances progress to 0.8', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'baggage', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationProgress, 0.8);
      await controller.close();
      await bloc.close();
    });

    test('budget event advances progress to 0.9', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'budget', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationProgress, 0.9);
      await controller.close();
      await bloc.close();
    });

    test(
      'complete with tripPlan builds TripPlan and advances to step 5',
      () async {
        final controller = StreamController<Map<String, dynamic>>();
        final bloc = await bootGeneratingBloc(controller);

        controller.add({
          'event': 'complete',
          'data': {
            'tripPlan': {
              'destination': {
                'city': 'Lisbon',
                'country': 'Portugal',
                'iata': 'LIS',
              },
              'duration_days': 6,
              'activities': [
                {
                  'title': 'Tram ride',
                  'description': 'Hop on the 28',
                  'category': 'CULTURE',
                },
                {
                  'title': 'Belém',
                  'description': 'Pastries',
                  'category': 'FOOD',
                },
              ],
              'accommodations': [
                {
                  'name': 'Hotel X',
                  'price_per_night': 120,
                  'currency': 'EUR',
                  'source': 'amadeus',
                },
              ],
              'baggage': [
                {'name': 'Passport', 'reason': 'ID'},
              ],
              'budget': {
                'flights': {
                  'amount': 200,
                  'source': 'amadeus',
                  'details': 'CDG→LIS',
                },
                'accommodation': {'amount': 720},
                'meals': {'amount': 180},
                'transport': {'amount': 60},
                'activities': {'amount': 40},
              },
              'weather': {'avg_temp_c': 21},
            },
          },
        });
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.currentStep, 5);
        expect(bloc.state.generationProgress, 1.0);
        final plan = bloc.state.generatedPlan!;
        expect(plan.destinationCity, 'Lisbon');
        expect(plan.durationDays, 6);
        expect(plan.budgetEur, 1200);
        expect(plan.highlights, ['Tram ride', 'Belém']);
        expect(plan.accommodationName, 'Hotel X');
        expect(plan.essentialItems, ['Passport']);

        await controller.close();
        await bloc.close();
      },
    );

    test('complete without tripPlan is a no-op', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'complete', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generatedPlan, isNull);
      await controller.close();
      await bloc.close();
    });

    test('error event sets generationError from payload', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({
        'event': 'error',
        'data': {'message': 'upstream failed'},
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.generationError, 'upstream failed');
      await controller.close();
      await bloc.close();
    });

    test('done with no plan advances to step 5 with empty plan', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      controller.add({'event': 'done', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.currentStep, 5);
      expect(bloc.state.generationProgress, 1.0);
      await controller.close();
      await bloc.close();
    });

    test('unknown event type is a no-op (default branch)', () async {
      final controller = StreamController<Map<String, dynamic>>();
      final bloc = await bootGeneratingBloc(controller);
      final before = bloc.state;
      controller.add({'event': 'sparkle', 'data': <String, dynamic>{}});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, before);
      await controller.close();
      await bloc.close();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2 — RequestAiSuggestions
  // ─────────────────────────────────────────────────────────────────────────

  group('requestAiSuggestions', () {
    const user = User(id: 'user-1', email: 'x@x');

    void stubStorage({
      String travelTypes = 'culture',
      String budget = 'medium',
      String companions = 'couple',
      String constraints = '',
    }) {
      when(
        () => mockStorage.getTravelTypes('user-1'),
      ).thenAnswer((_) async => travelTypes);
      when(
        () => mockStorage.getBudget('user-1'),
      ).thenAnswer((_) async => budget);
      when(
        () => mockStorage.getCompanions('user-1'),
      ).thenAnswer((_) async => companions);
      when(
        () => mockStorage.getConstraints('user-1'),
      ).thenAnswer((_) async => constraints);
    }

    blocTest<PlanTripBloc, PlanTripState>(
      'Success path parses suggestions and derives season from startDate',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Success(user));
        stubStorage();
        when(
          () => mockAiRepo.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).thenAnswer(
          (_) async => const Success([
            {
              'city': 'Rome',
              'country': 'Italy',
              'iata': 'FCO',
              'match_reason': 'You love history',
            },
          ]),
        );
        return buildBloc();
      },
      seed: () => PlanTripState(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 8),
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.requestAiSuggestions()),
      expect: () => [
        isA<PlanTripState>().having(
          (s) => s.isLoadingAiSuggestions,
          'loading',
          true,
        ),
        isA<PlanTripState>()
            .having((s) => s.isLoadingAiSuggestions, 'loading', false)
            .having((s) => s.aiSuggestions, 'count', hasLength(1)),
      ],
      verify: (bloc) {
        expect(bloc.state.aiSuggestions.first.city, 'Rome');
        expect(bloc.state.aiSuggestions.first.matchReason, 'You love history');
        verify(
          () => mockAiRepo.getInspiration(
            travelTypes: 'culture',
            budgetRange: 'medium',
            durationDays: 7,
            companions: 'couple',
            season: 'été',
            constraints: null,
          ),
        ).called(1);
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'derives season from preferredMonth when startDate is null',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Success(user));
        stubStorage();
        when(
          () => mockAiRepo.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).thenAnswer(
          (_) async => const Success([
            {'city': 'Oslo', 'country': 'Norway'},
          ]),
        );
        return buildBloc();
      },
      seed: () => const PlanTripState(
        preferredMonth: 12,
        preferredYear: 2026,
        dateMode: DateMode.month,
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.requestAiSuggestions()),
      verify: (_) {
        verify(
          () => mockAiRepo.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: 'hiver',
            constraints: any(named: 'constraints'),
          ),
        ).called(1);
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'empty suggestion list emits error state',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Success(user));
        stubStorage();
        when(
          () => mockAiRepo.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).thenAnswer((_) async => const Success([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlanTripEvent.requestAiSuggestions()),
      verify: (bloc) {
        expect(bloc.state.error, isA<UnknownError>());
        expect(bloc.state.aiSuggestions, isEmpty);
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'Failure surfaces error',
      build: () {
        when(
          () => mockAuthRepo.getCurrentUser(),
        ).thenAnswer((_) async => const Success(user));
        stubStorage();
        when(
          () => mockAiRepo.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlanTripEvent.requestAiSuggestions()),
      verify: (bloc) {
        expect(bloc.state.error, isA<NetworkError>());
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'unexpected exception is wrapped in UnknownError',
      build: () {
        when(() => mockAuthRepo.getCurrentUser()).thenThrow(Exception('boom'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlanTripEvent.requestAiSuggestions()),
      verify: (bloc) {
        expect(bloc.state.error, isA<UnknownError>());
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SwipeProposal
  // ─────────────────────────────────────────────────────────────────────────

  group('swipeProposal', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'selects the destination at the swiped index and advances to step 4',
      build: buildBloc,
      seed: () => const PlanTripState(
        aiSuggestions: [
          AiDestination(city: 'Rome', country: 'Italy'),
          AiDestination(city: 'Lisbon', country: 'Portugal'),
        ],
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.swipeProposal(1)),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.selectedAiDestination?.city, 'city', 'Lisbon')
            .having((s) => s.currentStep, 'step', 4),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'out-of-range index is a no-op',
      build: buildBloc,
      seed: () => const PlanTripState(
        aiSuggestions: [AiDestination(city: 'Rome', country: 'Italy')],
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.swipeProposal(99)),
      expect: () => <PlanTripState>[],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Misc setters + updateReviewDates + AI create path + manual failure
  // ─────────────────────────────────────────────────────────────────────────

  group('misc setters', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'setOriginCity updates originCity',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.setOriginCity('Paris')),
      expect: () => [
        isA<PlanTripState>().having((s) => s.originCity, 'origin', 'Paris'),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'updateReviewDates sets dates and flips dateMode to exact',
      build: buildBloc,
      seed: () => const PlanTripState(dateMode: DateMode.flexible),
      act: (bloc) => bloc.add(
        PlanTripEvent.updateReviewDates(
          DateTime(2026, 5),
          DateTime(2026, 5, 10),
        ),
      ),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.dateMode, 'mode', DateMode.exact)
            .having((s) => s.startDate, 'start', DateTime(2026, 5))
            .having((s) => s.endDate, 'end', DateTime(2026, 5, 10)),
      ],
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'setTravelerCounts clamps values to [min, max] range',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const PlanTripEvent.setTravelerCounts(
          adults: 0, // clamped up to 1
          children: 99, // clamped down to 10
          babies: 5,
        ),
      ),
      expect: () => [
        isA<PlanTripState>()
            .having((s) => s.nbAdults, 'adults', 1)
            .having((s) => s.nbChildren, 'children', 10)
            .having((s) => s.nbBabies, 'babies', 5),
      ],
    );
  });

  group('create trip — AI flow', () {
    blocTest<PlanTripBloc, PlanTripState>(
      'accepts the generated plan and stores createdTripId',
      build: () {
        when(
          () => mockAiRepo.acceptInspiration(
            any(),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            dateMode: any(named: 'dateMode'),
            originCity: any(named: 'originCity'),
          ),
        ).thenAnswer(
          (_) async => const Success(<String, dynamic>{'id': 'trip-42'}),
        );
        return buildBloc();
      },
      seed: () => PlanTripState(
        generatedPlan: const TripPlan(
          destinationCity: 'Lisbon',
          destinationCountry: 'Portugal',
          durationDays: 5,
          budgetEur: 1000,
          accommodationName: 'Hotel X',
          accommodationPrice: 120,
          accommodationSource: 'amadeus',
          flightRoute: 'CDG→LIS',
          flightDetails: 'AF123',
          flightPrice: 200,
          flightSource: 'amadeus',
          dayProgram: ['Tram ride'],
          dayDescriptions: ['Hop on the 28'],
          dayCategories: ['CULTURE'],
          essentialItems: ['Passport'],
          essentialReasons: ['ID'],
          highlights: [],
        ),
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 7),
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      verify: (bloc) {
        expect(bloc.state.createdTripId, 'trip-42');
        expect(bloc.state.isCreating, false);
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'falls back to tripId key when id is absent',
      build: () {
        when(
          () => mockAiRepo.acceptInspiration(
            any(),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            dateMode: any(named: 'dateMode'),
            originCity: any(named: 'originCity'),
          ),
        ).thenAnswer(
          (_) async => const Success(<String, dynamic>{'tripId': 't-7'}),
        );
        return buildBloc();
      },
      seed: () => PlanTripState(
        generatedPlan: const TripPlan(
          destinationCity: 'X',
          destinationCountry: 'Y',
          durationDays: 3,
          budgetEur: 100,
          accommodationName: '',
          accommodationPrice: 0,
          accommodationSource: 'estimated',
          flightRoute: '',
          flightDetails: '',
          flightPrice: 0,
          flightSource: 'estimated',
          dayProgram: [],
          dayDescriptions: [],
          dayCategories: [],
          essentialItems: [],
          essentialReasons: [],
          highlights: [],
        ),
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 4),
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      verify: (bloc) {
        expect(bloc.state.createdTripId, 't-7');
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'createTrip (AI) without generatedPlan surfaces ServerError',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      verify: (bloc) {
        expect(bloc.state.error, isA<ServerError>());
        expect(bloc.state.isCreating, false);
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'AI create failure surfaces error',
      build: () {
        when(
          () => mockAiRepo.acceptInspiration(
            any(),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            dateMode: any(named: 'dateMode'),
            originCity: any(named: 'originCity'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
        return buildBloc();
      },
      seed: () => PlanTripState(
        generatedPlan: const TripPlan(
          destinationCity: 'X',
          destinationCountry: 'Y',
          durationDays: 3,
          budgetEur: 100,
          accommodationName: '',
          accommodationPrice: 0,
          accommodationSource: 'estimated',
          flightRoute: '',
          flightDetails: '',
          flightPrice: 0,
          flightSource: 'estimated',
          dayProgram: [],
          dayDescriptions: [],
          dayCategories: [],
          essentialItems: [],
          essentialReasons: [],
          highlights: [],
        ),
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 4),
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      verify: (bloc) {
        expect(bloc.state.error, isA<NetworkError>());
      },
    );

    blocTest<PlanTripBloc, PlanTripState>(
      'manual create failure surfaces error',
      build: () {
        when(
          () => mockTripRepo.createTrip(
            title: any(named: 'title'),
            destinationName: any(named: 'destinationName'),
            destinationIata: any(named: 'destinationIata'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            nbTravelers: any(named: 'nbTravelers'),
            budgetTotal: any(named: 'budgetTotal'),
          ),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
        return buildBloc();
      },
      seed: () => PlanTripState(
        isManualFlow: true,
        selectedManualDestination: const LocationResult(
          name: 'Rome',
          iataCode: 'FCO',
        ),
        startDate: DateTime(2026, 5),
        endDate: DateTime(2026, 5, 8),
        budgetPreset: BudgetPreset.comfortable,
      ),
      act: (bloc) => bloc.add(const PlanTripEvent.createTrip()),
      verify: (bloc) {
        expect(bloc.state.error, isA<NetworkError>());
        expect(bloc.state.isCreating, false);
      },
    );
  });
}
