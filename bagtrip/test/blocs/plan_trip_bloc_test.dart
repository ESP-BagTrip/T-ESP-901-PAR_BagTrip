import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/plan_trip/bloc/plan_trip_bloc.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/mock_services.dart';

Trip _makeTrip() =>
    const Trip(id: 'trip-1', title: 'Barcelona', status: TripStatus.planned);

void main() {
  late MockLocationService mockLocationService;
  late MockTripRepository mockTripRepo;
  late MockAiRepository mockAiRepo;
  late MockAuthRepository mockAuthRepo;
  late MockPersonalizationStorage mockStorage;

  setUp(() {
    mockLocationService = MockLocationService();
    mockTripRepo = MockTripRepository();
    mockAiRepo = MockAiRepository();
    mockAuthRepo = MockAuthRepository();
    mockStorage = MockPersonalizationStorage();
  });

  PlanTripBloc buildBloc() => PlanTripBloc(
    locationService: mockLocationService,
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
      seed: () => const PlanTripState(error: 'some error'),
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
      const state = PlanTripState(flexibleDuration: DurationPreset.twoWeeks);
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
      'SetTravelers updates count',
      build: buildBloc,
      act: (bloc) => bloc.add(const PlanTripEvent.setTravelers(3)),
      expect: () => [
        isA<PlanTripState>().having((s) => s.nbTravelers, 'count', 3),
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
      'successful search populates results',
      build: () {
        when(
          () => mockLocationService.searchLocationsByKeyword(
            'Paris',
            'CITY,AIRPORT',
          ),
        ).thenAnswer(
          (_) async => const Success([
            {
              'name': 'Paris CDG',
              'iataCode': 'CDG',
              'city': 'Paris',
              'countryCode': 'FR',
              'countryName': 'France',
              'subType': 'AIRPORT',
            },
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PlanTripEvent.searchDestination('Paris')),
      expect: () => [
        isA<PlanTripState>().having((s) => s.isSearching, 'searching', true),
        isA<PlanTripState>()
            .having((s) => s.isSearching, 'searching', false)
            .having((s) => s.searchResults.length, 'count', 1)
            .having((s) => s.searchResults.first.iataCode, 'iata', 'CDG'),
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
        nbTravelers: 2,
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
}
