import 'dart:async';

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:bagtrip/plan_trip/helpers/budget_estimation.dart';
import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:bagtrip/plan_trip/models/budget_preset.dart';
import 'package:bagtrip/plan_trip/models/date_mode.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:bagtrip/plan_trip/models/location_result.dart';
import 'package:bagtrip/plan_trip/models/step_status.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/geo_location_service.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_trip_event.dart';
part 'plan_trip_state.dart';
part 'plan_trip_bloc.freezed.dart';

class PlanTripBloc extends Bloc<PlanTripEvent, PlanTripState> {
  final TripRepository _tripRepository;
  final AiRepository _aiRepository;
  final AuthRepository _authRepository;
  final PersonalizationStorage _storage;
  final LocationService _locationService;
  final GeoLocationService _geoService;

  StreamSubscription<Map<String, dynamic>>? _sseSubscription;

  PlanTripBloc({
    TripRepository? tripRepository,
    AiRepository? aiRepository,
    AuthRepository? authRepository,
    PersonalizationStorage? personalizationStorage,
    LocationService? locationService,
    GeoLocationService? geoLocationService,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _aiRepository = aiRepository ?? getIt<AiRepository>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       _storage = personalizationStorage ?? getIt<PersonalizationStorage>(),
       _locationService = locationService ?? getIt<LocationService>(),
       _geoService = geoLocationService ?? getIt<GeoLocationService>(),
       super(const PlanTripState()) {
    // Init
    on<PlanTripLoadPersonalization>(_onLoadPersonalization);
    // Navigation
    on<PlanTripNextStep>(_onNextStep);
    on<PlanTripPreviousStep>(_onPreviousStep);
    on<PlanTripGoToStep>(_onGoToStep);
    // Step 0 — Dates
    on<PlanTripSetDateMode>(_onSetDateMode);
    on<PlanTripSetExactDates>(_onSetExactDates);
    on<PlanTripSetMonthPreference>(_onSetMonthPreference);
    on<PlanTripSetFlexibleDuration>(_onSetFlexibleDuration);
    // Step 1 — Travelers + Budget
    on<PlanTripSetTravelerCounts>(_onSetTravelerCounts);
    on<PlanTripSetBudgetPreset>(_onSetBudgetPreset);
    on<PlanTripSetOriginCity>(_onSetOriginCity);
    on<PlanTripSearchOrigin>(_onSearchOrigin);
    // Step 2 — Destination
    on<PlanTripSearchDestination>(_onSearchDestination);
    on<PlanTripSelectManualDestination>(_onSelectManualDestination);
    on<PlanTripRequestAiSuggestions>(_onRequestAiSuggestions);
    on<PlanTripSelectAiDestination>(_onSelectAiDestination);
    // Step 3 — Proposals
    on<PlanTripSwipeProposal>(_onSwipeProposal);
    // Step 4 — Generation
    on<PlanTripStartGeneration>(_onStartGeneration);
    on<PlanTripRetryGeneration>(_onRetryGeneration);
    // Step 5 — Review
    on<PlanTripCreateTrip>(_onCreateTrip);
    on<PlanTripBackToProposals>(_onBackToProposals);
    on<PlanTripUpdateReviewDates>(_onUpdateReviewDates);
  }

  // ---------------------------------------------------------------------------
  // Init — pre-fill from personalization
  // ---------------------------------------------------------------------------

  Future<void> _onLoadPersonalization(
    PlanTripLoadPersonalization event,
    Emitter<PlanTripState> emit,
  ) async {
    try {
      final userResult = await _authRepository.getCurrentUser();
      if (isClosed) return;
      final userId = userResult.dataOrNull?.id ?? '';
      if (userId.isEmpty) return;

      final companions = await _storage.getCompanions(userId);
      if (isClosed) return;
      final budget = await _storage.getBudget(userId);
      if (isClosed) return;

      int? adults;
      int? children;
      int? babies;
      if (companions.isNotEmpty) {
        (adults, children, babies) = _companionDefaults(companions);
      }

      BudgetPreset? budgetPreset;
      if (budget.isNotEmpty) {
        budgetPreset = _mapBudgetPreset(budget);
      }

      if (adults != null || budgetPreset != null) {
        emit(
          state.copyWith(
            nbAdults: adults ?? state.nbAdults,
            nbChildren: children ?? state.nbChildren,
            nbBabies: babies ?? state.nbBabies,
            budgetPreset: budgetPreset ?? state.budgetPreset,
          ),
        );
      }

      // Pre-fill origin from device geolocation (best-effort, non-blocking)
      if (state.originCity == null || state.originCity!.isEmpty) {
        final geoResult = await _geoService.getNearestCity();
        if (isClosed) return;
        if (geoResult case Success(:final data)) {
          if (data.name.isNotEmpty) {
            emit(state.copyWith(originCity: data.name));
          }
        }
      }
    } catch (_) {
      // Pre-fill is best-effort — user can still set values manually.
    }
  }

  static (int, int, int) _companionDefaults(String companions) {
    return switch (companions) {
      'solo' => (1, 0, 0),
      'couple' => (2, 0, 0),
      'family' => (2, 2, 0),
      'friends' => (3, 0, 0),
      _ => (1, 0, 0),
    };
  }

  static BudgetPreset? _mapBudgetPreset(String budget) {
    return switch (budget) {
      'economical' => BudgetPreset.backpacker,
      'moderate' => BudgetPreset.comfortable,
      'comfort' => BudgetPreset.premium,
      'luxury' => BudgetPreset.noLimit,
      _ => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _onNextStep(PlanTripNextStep event, Emitter<PlanTripState> emit) {
    var next = state.currentStep + 1;

    // Skip proposals step (3) for manual flow
    if (state.isManualFlow && next == 3) next = 4;

    if (next < state.totalSteps) {
      emit(state.copyWith(currentStep: next, error: null));
    }
  }

  void _onPreviousStep(
    PlanTripPreviousStep event,
    Emitter<PlanTripState> emit,
  ) {
    // Leaving generation should feel instant; cancel stream in background.
    if (state.currentStep == 4) {
      unawaited(_cancelSseStream());
      emit(
        state.copyWith(
          generatedPlan: null,
          generationError: null,
          generationSteps: {},
          generationProgress: 0.0,
          generationMessage: null,
        ),
      );
    }

    var prev = state.currentStep - 1;

    // Skip proposals step (3) for manual flow going back
    if (state.isManualFlow && prev == 3) prev = 2;

    if (prev >= 0) {
      emit(state.copyWith(currentStep: prev, error: null));
    }
  }

  void _onGoToStep(PlanTripGoToStep event, Emitter<PlanTripState> emit) {
    if (event.step >= 0 && event.step < state.totalSteps) {
      emit(state.copyWith(currentStep: event.step, error: null));
    }
  }

  // ---------------------------------------------------------------------------
  // Step 0 — Dates
  // ---------------------------------------------------------------------------

  void _onSetDateMode(PlanTripSetDateMode event, Emitter<PlanTripState> emit) {
    emit(state.copyWith(dateMode: event.mode));
  }

  void _onSetExactDates(
    PlanTripSetExactDates event,
    Emitter<PlanTripState> emit,
  ) {
    emit(state.copyWith(startDate: event.start, endDate: event.end));
  }

  void _onSetMonthPreference(
    PlanTripSetMonthPreference event,
    Emitter<PlanTripState> emit,
  ) {
    emit(
      state.copyWith(preferredMonth: event.month, preferredYear: event.year),
    );
  }

  void _onSetFlexibleDuration(
    PlanTripSetFlexibleDuration event,
    Emitter<PlanTripState> emit,
  ) {
    emit(state.copyWith(flexibleDuration: event.preset));
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Travelers + Budget
  // ---------------------------------------------------------------------------

  static const int _maxTravelersPerCategory = 10;

  void _onSetTravelerCounts(
    PlanTripSetTravelerCounts event,
    Emitter<PlanTripState> emit,
  ) {
    final adults = (event.adults ?? state.nbAdults).clamp(
      1,
      _maxTravelersPerCategory,
    );
    final children = (event.children ?? state.nbChildren).clamp(
      0,
      _maxTravelersPerCategory,
    );
    final babies = (event.babies ?? state.nbBabies).clamp(
      0,
      _maxTravelersPerCategory,
    );
    emit(
      state.copyWith(nbAdults: adults, nbChildren: children, nbBabies: babies),
    );
  }

  void _onSetBudgetPreset(
    PlanTripSetBudgetPreset event,
    Emitter<PlanTripState> emit,
  ) {
    // Topic 01 — derive the numeric target as soon as the user picks a
    // preset (and trip days are known). Recomputed each time so the
    // value stays in sync with travelers / duration changes.
    double? targetBudget;
    if (event.preset != null && state.tripDurationDays != null) {
      final range = estimateBudget(
        preset: event.preset!,
        nbTravelers: state.nbTravelers,
        days: state.tripDurationDays!,
      );
      targetBudget = range.max;
    }
    emit(
      state.copyWith(budgetPreset: event.preset, targetBudget: targetBudget),
    );
  }

  void _onSetOriginCity(
    PlanTripSetOriginCity event,
    Emitter<PlanTripState> emit,
  ) {
    emit(state.copyWith(originCity: event.city, originSearchResults: []));
  }

  Future<void> _onSearchOrigin(
    PlanTripSearchOrigin event,
    Emitter<PlanTripState> emit,
  ) async {
    if (event.query.length < 2) {
      emit(state.copyWith(originSearchResults: []));
      return;
    }
    final result = await _locationService.searchLocationsByKeyword(
      event.query,
      'CITY',
    );
    if (isClosed) return;
    if (result case Success(:final data)) {
      final locations = data
          .take(6)
          .map(
            (m) => LocationResult(
              name: m['name'] as String? ?? '',
              iataCode: m['iataCode'] as String? ?? '',
              city: m['city'] as String? ?? '',
              countryCode: m['countryCode'] as String? ?? '',
              countryName: m['countryName'] as String? ?? '',
              subType: m['subType'] as String? ?? '',
            ),
          )
          .toList();
      emit(state.copyWith(originSearchResults: locations));
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Destination
  // ---------------------------------------------------------------------------

  Future<void> _onSearchDestination(
    PlanTripSearchDestination event,
    Emitter<PlanTripState> emit,
  ) async {
    if (event.query.length < 2) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }
    emit(state.copyWith(isSearching: true));
    final result = await _locationService.searchLocationsByKeyword(
      event.query,
      'CITY,AIRPORT',
    );
    if (isClosed) return;
    if (result case Success(:final data)) {
      final locations = data
          .take(8)
          .map(
            (m) => LocationResult(
              name: m['name'] as String? ?? '',
              iataCode: m['iataCode'] as String? ?? '',
              city: m['city'] as String? ?? '',
              countryCode: m['countryCode'] as String? ?? '',
              countryName: m['countryName'] as String? ?? '',
              subType: m['subType'] as String? ?? '',
            ),
          )
          .toList();
      emit(
        state.copyWith(
          isSearching: false,
          searchResults: locations,
          error: null,
        ),
      );
    } else {
      emit(state.copyWith(isSearching: false));
    }
  }

  void _onSelectManualDestination(
    PlanTripSelectManualDestination event,
    Emitter<PlanTripState> emit,
  ) {
    emit(
      state.copyWith(
        selectedManualDestination: event.location,
        searchResults: [],
        isManualFlow: true,
        selectedAiDestination: null,
      ),
    );
  }

  Future<void> _onRequestAiSuggestions(
    PlanTripRequestAiSuggestions event,
    Emitter<PlanTripState> emit,
  ) async {
    emit(state.copyWith(isLoadingAiSuggestions: true, error: null));

    try {
      final userResult = await _authRepository.getCurrentUser();
      if (isClosed) return;
      final userId = userResult.dataOrNull?.id ?? '';

      String? travelTypes;
      String? budget;
      String? companions;
      String? constraints;

      if (userId.isNotEmpty) {
        travelTypes = await _storage.getTravelTypes(userId);
        if (isClosed) return;
        budget = await _storage.getBudget(userId);
        if (isClosed) return;
        companions = await _storage.getCompanions(userId);
        if (isClosed) return;
        constraints = await _storage.getConstraints(userId);
        if (isClosed) return;

        travelTypes = travelTypes.isEmpty ? null : travelTypes;
        budget = budget.isEmpty ? null : budget;
        companions = companions.isEmpty ? null : companions;
        constraints = constraints.isEmpty ? null : constraints;
      }

      String? season;
      if (state.startDate != null) {
        final month = state.startDate!.month;
        season = switch (month) {
          >= 3 && <= 5 => 'printemps',
          >= 6 && <= 8 => 'été',
          >= 9 && <= 11 => 'automne',
          _ => 'hiver',
        };
      } else if (state.preferredMonth != null) {
        season = switch (state.preferredMonth!) {
          >= 3 && <= 5 => 'printemps',
          >= 6 && <= 8 => 'été',
          >= 9 && <= 11 => 'automne',
          _ => 'hiver',
        };
      }

      final result = await _aiRepository.getInspiration(
        travelTypes: travelTypes,
        budgetRange: budget,
        durationDays: state.tripDurationDays,
        companions: companions,
        season: season,
        constraints: constraints,
        locale: event.locale,
      );
      if (isClosed) return;

      switch (result) {
        case Success(:final data):
          final suggestions = data.map((m) {
            return AiDestination(
              city: m['city'] as String? ?? m['destination'] as String? ?? '',
              country:
                  m['country'] as String? ??
                  m['destinationCountry'] as String? ??
                  '',
              iata: m['iata'] as String?,
              matchReason:
                  m['match_reason'] as String? ?? m['matchReason'] as String?,
              imageUrl: m['image_url'] as String? ?? m['imageUrl'] as String?,
              weatherSummary:
                  m['weather_summary'] as String? ??
                  m['weatherSummary'] as String?,
              topActivities:
                  (m['topActivities'] as List?)?.cast<String>() ?? [],
            );
          }).toList();
          if (suggestions.isEmpty) {
            emit(
              state.copyWith(
                isLoadingAiSuggestions: false,
                error: const UnknownError(
                  'No destinations found. Try adjusting your preferences.',
                ),
              ),
            );
          } else {
            emit(
              state.copyWith(
                isLoadingAiSuggestions: false,
                aiSuggestions: suggestions,
                isManualFlow: false,
              ),
            );
          }
        case Failure(:final error):
          emit(state.copyWith(isLoadingAiSuggestions: false, error: error));
      }
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoadingAiSuggestions: false,
          error: UnknownError(
            'Failed to load AI suggestions',
            originalError: e,
          ),
        ),
      );
    }
  }

  void _onSelectAiDestination(
    PlanTripSelectAiDestination event,
    Emitter<PlanTripState> emit,
  ) {
    emit(
      state.copyWith(
        selectedAiDestination: event.destination,
        selectedManualDestination: null,
        isManualFlow: false,
        currentStep: 3,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Proposals (swipe)
  // ---------------------------------------------------------------------------

  void _onSwipeProposal(
    PlanTripSwipeProposal event,
    Emitter<PlanTripState> emit,
  ) {
    // Select the AI destination at the swiped index and advance to generation
    if (event.index >= 0 && event.index < state.aiSuggestions.length) {
      final destination = state.aiSuggestions[event.index];
      emit(state.copyWith(selectedAiDestination: destination, currentStep: 4));
    }
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Generation (SSE streaming)
  // ---------------------------------------------------------------------------

  Future<void> _onStartGeneration(
    PlanTripStartGeneration event,
    Emitter<PlanTripState> emit,
  ) async {
    // Check AI quota
    final userResult = await _authRepository.getCurrentUser();
    if (isClosed) return;
    final user = userResult.dataOrNull;
    if (user != null &&
        user.aiGenerationsRemaining != null &&
        user.aiGenerationsRemaining! <= 0) {
      emit(state.copyWith(generationError: 'AI generation quota exceeded'));
      return;
    }

    // Initialize generation steps
    final steps = <String, StepStatus>{
      'destinations': StepStatus.pending,
      'activities': StepStatus.pending,
      'accommodations': StepStatus.pending,
      'baggage': StepStatus.pending,
      'budget': StepStatus.pending,
    };

    emit(
      state.copyWith(
        generationSteps: steps,
        generationProgress: 0.0,
        generationMessage: 'Préparation de votre voyage...',
        generatedPlan: null,
        generationError: null,
      ),
    );

    // Load personalization prefs for SSE params
    final userId = user?.id ?? '';
    String? travelTypes;
    String? companions;
    String? constraints;

    if (userId.isNotEmpty) {
      travelTypes = await _storage.getTravelTypes(userId);
      if (isClosed) return;
      companions = await _storage.getCompanions(userId);
      if (isClosed) return;
      constraints = await _storage.getConstraints(userId);
      if (isClosed) return;

      if (travelTypes.isEmpty) travelTypes = null;
      if (companions.isEmpty) companions = null;
      if (constraints.isEmpty) constraints = null;
    }

    // Build SSE params
    final params = _buildSseParams(
      travelTypes: travelTypes,
      companions: companions,
      constraints: constraints,
    );

    // Start SSE stream with proper cancellation support
    await _cancelSseStream();

    final completer = Completer<void>();

    _sseSubscription = _aiRepository
        .planTripStream(
          travelTypes: params['travelTypes'] as String?,
          budgetRange: params['budgetRange'] as String?,
          durationDays: params['durationDays'] as int?,
          companions: params['companions'] as String?,
          constraints: params['constraints'] as String?,
          departureDate: params['departureDate'] as String?,
          returnDate: params['returnDate'] as String?,
          originCity: params['originCity'] as String?,
          destinationCity: params['destinationCity'] as String?,
          destinationIata: params['destinationIata'] as String?,
          locale: event.locale,
        )
        .listen(
          (sseEvent) {
            if (!isClosed) {
              emit(_handleSseEvent(sseEvent));
            }
          },
          onError: (Object error) {
            if (!isClosed) {
              emit(state.copyWith(generationError: 'Generation failed'));
            }
            if (!completer.isCompleted) completer.complete();
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );

    // Keep handler alive so emit remains valid (bloc ^9 requirement)
    await completer.future;
  }

  PlanTripState _handleSseEvent(Map<String, dynamic> sseEvent) {
    final eventType = sseEvent['event'] as String? ?? 'message';
    final data = sseEvent['data'] as Map<String, dynamic>? ?? {};

    switch (eventType) {
      case 'progress':
        return state.copyWith(
          generationMessage:
              data['message'] as String? ?? state.generationMessage,
        );

      case 'destinations':
        final updatedSteps = Map<String, StepStatus>.from(state.generationSteps)
          ..['destinations'] = StepStatus.completed
          ..['activities'] = StepStatus.inProgress;
        return state.copyWith(
          generationSteps: updatedSteps,
          generationProgress: 0.2,
        );

      case 'activities':
        final updatedSteps = Map<String, StepStatus>.from(state.generationSteps)
          ..['activities'] = StepStatus.completed
          ..['accommodations'] = StepStatus.inProgress;
        return state.copyWith(
          generationSteps: updatedSteps,
          generationProgress: 0.4,
        );

      case 'accommodations':
        final updatedSteps = Map<String, StepStatus>.from(state.generationSteps)
          ..['accommodations'] = StepStatus.completed
          ..['baggage'] = StepStatus.inProgress;
        return state.copyWith(
          generationSteps: updatedSteps,
          generationProgress: 0.6,
        );

      case 'baggage':
        final updatedSteps = Map<String, StepStatus>.from(state.generationSteps)
          ..['baggage'] = StepStatus.completed
          ..['budget'] = StepStatus.inProgress;
        return state.copyWith(
          generationSteps: updatedSteps,
          generationProgress: 0.8,
        );

      case 'budget':
        final updatedSteps = Map<String, StepStatus>.from(state.generationSteps)
          ..['budget'] = StepStatus.completed;
        return state.copyWith(
          generationSteps: updatedSteps,
          generationProgress: 0.9,
        );

      case 'complete':
        final tripPlanData = data['tripPlan'] as Map<String, dynamic>?;
        if (tripPlanData != null) {
          final plan = _tripPlanFromSseData(tripPlanData);
          return state.copyWith(
            generatedPlan: plan,
            generationProgress: 1.0,
            currentStep: 5,
          );
        }
        return state;

      case 'error':
        return state.copyWith(
          generationError: data['message'] as String? ?? 'Stream error',
        );

      case 'done':
        if (state.generatedPlan == null) {
          // Fallback: advance to review with empty plan
          return state.copyWith(generationProgress: 1.0, currentStep: 5);
        }
        return state;

      default:
        return state;
    }
  }

  Future<void> _onRetryGeneration(
    PlanTripRetryGeneration event,
    Emitter<PlanTripState> emit,
  ) async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    add(PlanTripEvent.startGeneration(locale: event.locale));
  }

  // ---------------------------------------------------------------------------
  // Step 5 — Review / Create
  // ---------------------------------------------------------------------------

  Future<void> _onCreateTrip(
    PlanTripCreateTrip event,
    Emitter<PlanTripState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, error: null));

    if (state.isManualFlow) {
      await _createManualTrip(emit);
    } else {
      await _createAiTrip(emit);
    }
  }

  Future<void> _createManualTrip(Emitter<PlanTripState> emit) async {
    final dest = state.selectedManualDestination;
    final title = dest?.name ?? 'Mon voyage';

    // Topic 01 (B7) — manual flow now reuses the same `targetBudget` the
    // wizard committed to in step 2, instead of recomputing it differently
    // from the IA flow (which used to produce a different total user-side).
    final result = await _tripRepository.createTrip(
      title: title,
      destinationName: dest?.name,
      destinationIata: dest?.iataCode,
      startDate: state.startDate,
      endDate: state.endDate,
      nbTravelers: state.nbTravelers,
      budgetTarget: state.targetBudget,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        emit(state.copyWith(isCreating: false, createdTripId: data.id));
      case Failure(:final error):
        emit(state.copyWith(isCreating: false, error: error));
    }
  }

  Future<void> _createAiTrip(Emitter<PlanTripState> emit) async {
    final plan = state.generatedPlan;
    if (plan == null) {
      emit(
        state.copyWith(
          isCreating: false,
          error: const ServerError('No plan generated'),
        ),
      );
      return;
    }

    final suggestion = _tripPlanToSuggestion(plan);

    // Always derive dates (handles month/flexible modes)
    final (start, end) = state.representativeDates;
    final startDateStr = start.toIso8601String().split('T')[0];
    final endDateStr = end.toIso8601String().split('T')[0];

    final result = await _aiRepository.acceptInspiration(
      suggestion,
      startDate: startDateStr,
      endDate: endDateStr,
      dateMode: state.dateMode.name,
      originCity: state.originCity,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        final tripId =
            data['id']?.toString() ?? data['tripId']?.toString() ?? '';
        emit(state.copyWith(isCreating: false, createdTripId: tripId));
      case Failure(:final error):
        emit(state.copyWith(isCreating: false, error: error));
    }
  }

  Future<void> _onBackToProposals(
    PlanTripBackToProposals event,
    Emitter<PlanTripState> emit,
  ) async {
    unawaited(_cancelSseStream());
    emit(
      state.copyWith(
        currentStep: state.isManualFlow ? 2 : 3,
        generatedPlan: null,
        generationError: null,
        generationSteps: {},
        generationProgress: 0.0,
        generationMessage: null,
      ),
    );
  }

  void _onUpdateReviewDates(
    PlanTripUpdateReviewDates event,
    Emitter<PlanTripState> emit,
  ) {
    emit(
      state.copyWith(
        startDate: event.start,
        endDate: event.end,
        dateMode: DateMode.exact,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Collect wizard data into SSE request params.
  Map<String, dynamic> _buildSseParams({
    String? travelTypes,
    String? companions,
    String? constraints,
  }) {
    // Always derive dates via representativeDates (handles all modes)
    final (start, end) = state.representativeDates;
    final departureDate = start.toIso8601String().split('T')[0];
    final returnDate = end.toIso8601String().split('T')[0];

    // Resolve destination from manual or AI selection
    final destName =
        state.selectedManualDestination?.name ??
        state.selectedAiDestination?.city;
    final destIata =
        state.selectedManualDestination?.iataCode ??
        state.selectedAiDestination?.iata;

    return {
      'durationDays': state.effectiveDurationDays,
      'departureDate': departureDate,
      'returnDate': returnDate,
      // Topic 05 (B4) — `budgetRange` was a duplicate of `budgetPreset`
      // (same enum value, two keys). Dropped.
      'nbTravelers': state.nbTravelers,
      'originCity': state.originCity,
      'dateMode': state.dateMode.name,
      'budgetPreset': state.budgetPreset?.name,
      // Topic 01 — surface the numeric target so the agent treats it as a
      // constraint instead of recomputing it from the breakdown.
      if (state.targetBudget != null) 'targetBudget': state.targetBudget,
      if (state.preferredMonth != null) 'preferredMonth': state.preferredMonth,
      if (state.preferredYear != null) 'preferredYear': state.preferredYear,
      if (destName != null) 'destinationCity': destName,
      if (destIata != null) 'destinationIata': destIata,
      if (travelTypes != null) 'travelTypes': travelTypes,
      if (companions != null) 'companions': companions,
      if (constraints != null) 'constraints': constraints,
    };
  }

  /// Convert SSE 'complete' tripPlan data to [TripPlan].
  ///
  /// Ported from the legacy CreateTripAiBloc._tripPlanToSummary method, adapted to produce
  /// [TripPlan] instead of [TripSummary].
  TripPlan _tripPlanFromSseData(Map<String, dynamic> tripPlan) {
    final dest = tripPlan['destination'] as Map<String, dynamic>? ?? {};
    final originIata = tripPlan['origin_iata'] as String? ?? '';
    final weather = tripPlan['weather'] as Map<String, dynamic>? ?? {};
    final activities =
        (tripPlan['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final accommodations =
        (tripPlan['accommodations'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final baggage =
        (tripPlan['baggage'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final budget = tripPlan['budget'] as Map<String, dynamic>? ?? {};
    final flightOffers =
        (tripPlan['flight_offers'] as List?)?.cast<Map<String, dynamic>>() ??
        [];

    // Highlights from top activities
    final highlights = activities
        .take(4)
        .map((a) => (a['title'] ?? '') as String)
        .toList();

    // Best accommodation — store the *per-night* price. Reading
    // `price_total` here used to feed a stay total to a field labeled
    // per-night, which the backend then re-multiplied by trip nights
    // (B23 / topic 04a). Prefer the explicit per-night unit; fall back
    // to dividing the stay total by `nights` when the tool only emitted
    // a total.
    //
    // When the backend returns a deferred-marker (Amadeus unavailable
    // → name="" / prices=null / source="deferred"), we leave the
    // values empty and let the review view render an l10n
    // "accommodation to be chosen" placeholder rather than fabricating
    // a hotel name and a price the front would display without unit.
    String accommodationName = '';
    String accommodationSubtitle = '';
    double accommodationPrice = 0;
    String accommodationSource = 'deferred';
    if (accommodations.isNotEmpty) {
      final best = accommodations.first;
      final rawName = (best['name'] as String?) ?? '';
      accommodationSource = best['source'] as String? ?? 'estimated';
      if (rawName.isNotEmpty) {
        accommodationName = rawName;
        final perNight = (best['price_per_night'] as num?)?.toDouble();
        final priceTotal = (best['price_total'] as num?)?.toDouble();
        final nightsRaw = (best['nights'] as num?)?.toInt() ?? 0;
        if (perNight != null && perNight > 0) {
          accommodationPrice = perNight;
        } else if (priceTotal != null && priceTotal > 0 && nightsRaw > 0) {
          accommodationPrice = priceTotal / nightsRaw;
        } else {
          accommodationPrice = 0;
        }
        if (accommodationPrice > 0) {
          // Subtitle is built by the view via l10n.accommodationPerNight
          // so the unit suffix is consistent across locales; we hand it
          // a pre-formatted "{city} · {amount}" string for backwards
          // compatibility with consumers that still read this field.
          final currency = best['currency'] as String? ?? 'EUR';
          accommodationSubtitle =
              '${dest['city'] ?? ''} · ${accommodationPrice.toStringAsFixed(0)} $currency/nuit';
        } else {
          accommodationSubtitle = '${dest['city'] ?? ''}';
        }
      }
    }

    // Flight info from budget
    String flightRoute = '';
    String flightDetails = '';
    double flightPrice = 0;
    String flightSource = 'estimated';
    // Topic 05 (B12) — singular keys aligned with Flutter BudgetCategory.
    final flightBudget = budget['flight'] as Map<String, dynamic>?;
    if (flightBudget != null) {
      flightPrice = (flightBudget['amount'] as num?)?.toDouble() ?? 0;
      flightSource = flightBudget['source'] as String? ?? 'estimated';
      flightDetails = flightBudget['details'] as String? ?? '';
      flightRoute = flightBudget['details'] as String? ?? '';
    }

    // Best flight offer from Amadeus (raw data for display)
    String flightAirline = '';
    String flightNumber = '';
    String flightDepartureIso = '';
    String flightArrivalIso = '';
    String flightDurationIso = '';
    String returnDepartureIso = '';
    String returnArrivalIso = '';
    String returnDurationIso = '';
    if (flightOffers.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(flightOffers)
        ..sort(
          (a, b) => ((a['price'] as num?) ?? double.maxFinite).compareTo(
            (b['price'] as num?) ?? double.maxFinite,
          ),
        );
      final best = sorted.first;
      flightAirline =
          best['airline_name'] as String? ?? best['airline'] as String? ?? '';
      flightNumber = best['flight_number'] as String? ?? '';
      flightDepartureIso = best['departure'] as String? ?? '';
      flightArrivalIso = best['arrival'] as String? ?? '';
      flightDurationIso = best['duration'] as String? ?? '';
      returnDepartureIso = best['return_departure'] as String? ?? '';
      returnArrivalIso = best['return_arrival'] as String? ?? '';
      returnDurationIso = best['return_duration'] as String? ?? '';
    }

    // Hotel rating
    int hotelRating = 0;
    if (accommodations.isNotEmpty) {
      hotelRating = (accommodations.first['rating'] as num?)?.toInt() ?? 0;
    }

    // SMP-324 — partition the agent's flat ``activities`` list into the
    // three buckets the review screen renders separately:
    //
    //  - dated itinerary entries (CULTURE / NATURE / SPORT / ...) feed
    //    the day-by-day timeline as before;
    //  - undated FOOD entries become the "Restos à essayer" section;
    //  - undated TRANSPORT entries become the "Transports utiles"
    //    section.
    //
    // Categorisation is permissive: anything tagged FOOD / TRANSPORT
    // *without* a slot lands in the recommendation bucket regardless
    // of the order the LLM put it in. Anything else stays in the
    // dated timeline, falling back to the activity index for the day
    // when the agent forgot to attach a slot.
    final datedActivities = <Map<String, dynamic>>[];
    final mealReco = <TripRecommendation>[];
    final transportReco = <TripRecommendation>[];

    for (final a in activities) {
      final category = ((a['category'] ?? 'OTHER') as String).toUpperCase();
      final hasSlot =
          a['suggested_day'] != null || a['time_of_day'] != null;
      final estimatedCost =
          (a['estimated_cost'] as num?)?.toDouble() ??
          (a['estimatedCost'] as num?)?.toDouble() ??
          0.0;

      if (!hasSlot && category == 'FOOD') {
        mealReco.add(
          TripRecommendation(
            title: (a['title'] ?? '') as String,
            description: (a['description'] ?? '') as String,
            estimatedCost: estimatedCost,
            location: (a['location'] ?? '') as String,
          ),
        );
        continue;
      }
      if (!hasSlot && category == 'TRANSPORT') {
        transportReco.add(
          TripRecommendation(
            title: (a['title'] ?? '') as String,
            description: (a['description'] ?? '') as String,
            estimatedCost: estimatedCost,
            location: (a['location'] ?? '') as String,
          ),
        );
        continue;
      }
      datedActivities.add(a);
    }

    final dayProgram = datedActivities
        .map((a) => (a['title'] ?? '') as String)
        .toList();
    final dayDescriptions = datedActivities
        .map((a) => (a['description'] ?? '') as String)
        .toList();
    final dayCategories = datedActivities
        .map((a) => (a['category'] ?? 'OTHER') as String)
        .toList();

    // Essential items from baggage
    final essentialItems = baggage
        .map((b) => (b['name'] ?? '') as String)
        .toList();
    final essentialReasons = baggage
        .map((b) => (b['reason'] ?? '') as String)
        .toList();

    // Budget total — sum breakdown categories for consistency with chart.
    // Topic 03 (B5) — accumulate as `double` so we don't drop the decimals.
    // Topic 05 (B12) — singular keys aligned with Flutter BudgetCategory.
    double budgetEur = 0;
    for (final key in [
      'flight',
      'accommodation',
      'food',
      'transport',
      'activity',
    ]) {
      final value = budget[key];
      if (value is Map) {
        final raw = value['amount'];
        if (raw is num) budgetEur += raw.toDouble();
      } else if (value is num) {
        budgetEur += value.toDouble();
      }
    }
    if (budgetEur == 0) {
      // Fallback to LLM totals if no breakdown entries
      final totalMax = (budget['total_max'] as num?)?.toDouble() ?? 0;
      final totalMin = (budget['total_min'] as num?)?.toDouble() ?? 0;
      budgetEur = totalMax > 0 ? totalMax : totalMin;
    }
    if (budgetEur == 0) {
      // Last-resort fallback: sum already-extracted real prices
      double fallbackTotal = accommodationPrice + flightPrice;
      for (final a in activities) {
        final cost = a['estimated_cost'];
        if (cost is num) fallbackTotal += cost;
      }
      budgetEur = fallbackTotal;
    }

    return TripPlan(
      destinationCity: dest['city'] as String? ?? '',
      destinationCountry: dest['country'] as String? ?? '',
      destinationIata: dest['iata'] as String?,
      durationDays: tripPlan['duration_days'] as int? ?? 7,
      budgetEur: budgetEur,
      highlights: highlights,
      accommodationName: accommodationName,
      accommodationSubtitle: accommodationSubtitle,
      accommodationPrice: accommodationPrice,
      accommodationSource: accommodationSource,
      flightRoute: flightRoute,
      flightDetails: flightDetails,
      flightPrice: flightPrice,
      flightSource: flightSource,
      originIata: originIata,
      flightAirline: flightAirline,
      flightNumber: flightNumber,
      flightDeparture: flightDepartureIso,
      flightArrival: flightArrivalIso,
      flightDuration: flightDurationIso,
      returnDeparture: returnDepartureIso,
      returnArrival: returnArrivalIso,
      returnDuration: returnDurationIso,
      hotelRating: hotelRating,
      dayProgram: dayProgram,
      dayDescriptions: dayDescriptions,
      dayCategories: dayCategories,
      mealRecommendations: mealReco,
      transportRecommendations: transportReco,
      essentialItems: essentialItems,
      essentialReasons: essentialReasons,
      budgetBreakdown: BudgetBreakdown.fromSseMap(budget),
      weatherData: weather,
    );
  }

  /// Convert [TripPlan] to suggestion format for `/ai/plan-trip/accept`.
  Map<String, dynamic> _tripPlanToSuggestion(TripPlan plan) {
    return {
      'destination': {
        'city': plan.destinationCity,
        'country': plan.destinationCountry,
        if (plan.destinationIata != null) 'iata': plan.destinationIata,
      },
      'durationDays': plan.durationDays,
      'budgetEur': plan.budgetEur,
      'description':
          'AI-planned trip to ${plan.destinationCity.isEmpty ? 'destination' : plan.destinationCity}',
      'activities': List.generate(plan.dayProgram.length, (i) {
        return {
          'title': plan.dayProgram[i],
          'description': i < plan.dayDescriptions.length
              ? plan.dayDescriptions[i]
              : '',
          'category': i < plan.dayCategories.length
              ? plan.dayCategories[i]
              : 'OTHER',
        };
      }),
      if (plan.accommodationName.isNotEmpty)
        'accommodations': [
          {
            'name': plan.accommodationName,
            'price_per_night': plan.accommodationPrice,
            'currency': 'EUR',
            'source': plan.accommodationSource,
          },
        ],
      // Flight gate: we want a flight persisted as soon as *any* layer produced
      // data — Amadeus horaires, LLM budget route, or even just the user's
      // origin/destination IATA. Gating on `flightPrice > 0` used to drop the
      // entire flight silently when the LLM omitted the budget breakdown even
      // though Amadeus had returned the offer (SMP-316 / Barcelone bug).
      if (_hasOutboundFlight(plan))
        'flight': {
          'route': _flightRouteOrDeriveFrom(plan),
          if (plan.flightDetails.isNotEmpty) 'details': plan.flightDetails,
          if (plan.flightPrice > 0) 'price': plan.flightPrice,
          'source': plan.flightSource,
          if (plan.flightAirline.isNotEmpty) 'airline': plan.flightAirline,
          if (plan.flightNumber.isNotEmpty) 'flight_number': plan.flightNumber,
          if (plan.flightDeparture.isNotEmpty)
            'departure_date': plan.flightDeparture,
          if (plan.flightArrival.isNotEmpty) 'arrival_date': plan.flightArrival,
          if (plan.flightDuration.isNotEmpty) 'duration': plan.flightDuration,
        },
      if (_hasReturnFlight(plan))
        'return_flight': {
          'route': _returnRouteOrDeriveFrom(plan),
          if (plan.flightDetails.isNotEmpty) 'details': plan.flightDetails,
          'source': plan.flightSource,
          if (plan.flightAirline.isNotEmpty) 'airline': plan.flightAirline,
          if (plan.flightNumber.isNotEmpty) 'flight_number': plan.flightNumber,
          if (plan.returnDeparture.isNotEmpty)
            'departure_date': plan.returnDeparture,
          if (plan.returnArrival.isNotEmpty) 'arrival_date': plan.returnArrival,
          if (plan.returnDuration.isNotEmpty) 'duration': plan.returnDuration,
        },
      'baggage': List.generate(plan.essentialItems.length, (i) {
        return {
          'name': plan.essentialItems[i],
          'reason': i < plan.essentialReasons.length
              ? plan.essentialReasons[i]
              : '',
        };
      }),
      // SMP-324 — the breakdown used to ride along here so the backend
      // could materialize orphan ``Repas estimés`` / ``Transport estimé``
      // budget lines. The agent now emits typed FOOD / TRANSPORT
      // recommendations as Activity rows, the persistence path covers
      // them via the same ``activities`` array, and the breakdown is
      // derived server-side. Shipping it again would only invite drift.
      'matchReason': 'Planned with real-time data',
    };
  }

  /// Whether we have *any* evidence of an outbound flight in the plan.
  /// Covers the three sources that populate TripPlan today: Amadeus (timestamps),
  /// LLM budget breakdown (route string), and the user's origin/destination
  /// IATA (which at worst yield a placeholder route).
  static bool _hasOutboundFlight(TripPlan plan) {
    if (plan.flightRoute.isNotEmpty) return true;
    if (plan.flightDeparture.isNotEmpty || plan.flightArrival.isNotEmpty) {
      return true;
    }
    final hasOrigin = plan.originIata.isNotEmpty;
    final hasDest = plan.destinationIata?.isNotEmpty ?? false;
    return hasOrigin && hasDest;
  }

  static bool _hasReturnFlight(TripPlan plan) {
    if (plan.returnDeparture.isNotEmpty || plan.returnArrival.isNotEmpty) {
      return true;
    }
    // If we have an outbound, a return is always implied at this stage — the
    // user can edit it later. Explicit return fields only exist when Amadeus
    // found a round-trip.
    return _hasOutboundFlight(plan);
  }

  static String _flightRouteOrDeriveFrom(TripPlan plan) {
    if (plan.flightRoute.isNotEmpty) return plan.flightRoute;
    final origin = plan.originIata;
    final dest = plan.destinationIata ?? '';
    if (origin.isEmpty && dest.isEmpty) return '';
    return '$origin → $dest'.trim();
  }

  static String _returnRouteOrDeriveFrom(TripPlan plan) {
    // Return leg swaps origin and destination.
    final origin = plan.originIata;
    final dest = plan.destinationIata ?? '';
    if (origin.isEmpty && dest.isEmpty) return plan.flightRoute;
    return '$dest → $origin'.trim();
  }

  Future<void> _cancelSseStream() async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSseStream();
    return super.close();
  }
}
