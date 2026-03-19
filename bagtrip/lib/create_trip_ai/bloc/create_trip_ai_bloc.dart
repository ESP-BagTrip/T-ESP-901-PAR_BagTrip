import 'dart:async';

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'create_trip_ai_event.dart';
part 'create_trip_ai_state.dart';

class CreateTripAiBloc extends Bloc<CreateTripAiEvent, CreateTripAiState> {
  CreateTripAiBloc({
    AuthRepository? authRepository,
    PersonalizationStorage? personalizationStorage,
    AiRepository? aiRepository,
  }) : _authRepository = authRepository ?? getIt<AuthRepository>(),
       _storage = personalizationStorage ?? getIt<PersonalizationStorage>(),
       _aiRepository = aiRepository ?? getIt<AiRepository>(),
       super(CreateTripAiInitial()) {
    on<CreateTripAiLoadRecap>(_onLoadRecap);
    on<CreateTripAiSetDepartureDate>(_onSetDepartureDate);
    on<CreateTripAiSetReturnDate>(_onSetReturnDate);
    on<CreateTripAiLaunchSearch>(_onLaunchSearch);
    on<CreateTripAiSelectProposal>(_onSelectProposal);
    on<CreateTripAiRegenerate>(_onRegenerate);
    on<CreateTripAiAcceptSuggestion>(_onAcceptSuggestion);
  }

  final AuthRepository _authRepository;
  final PersonalizationStorage _storage;
  final AiRepository _aiRepository;

  // Store the last recap to use in search calls
  String _lastTravelTypes = '';
  String? _lastBudget;
  String? _lastCompanions;
  String? _lastConstraints;
  DateTime? _lastDepartureDate;
  DateTime? _lastReturnDate;

  // Store the selected proposal (with activities) for save
  AiTripProposal? _selectedProposal;

  // Store the trip plan from streaming for accept
  Map<String, dynamic>? _lastTripPlan;

  Future<void> _onLoadRecap(
    CreateTripAiLoadRecap event,
    Emitter<CreateTripAiState> emit,
  ) async {
    emit(CreateTripAiRecapLoading());
    try {
      final userResult = await _authRepository.getCurrentUser();
      if (isClosed) return;
      final userId = userResult.dataOrNull?.id ?? '';
      String travelTypes = '';
      String? travelStyle;
      String? budget;
      String? companions;
      if (userId.isNotEmpty) {
        travelTypes = await _storage.getTravelTypes(userId);
        if (isClosed) return;
        travelStyle = await _storage.getTravelStyle(userId);
        if (isClosed) return;
        final b = await _storage.getBudget(userId);
        if (isClosed) return;
        travelStyle = travelStyle.isEmpty ? null : travelStyle;
        budget = b.isEmpty ? null : b;
        companions = await _storage.getCompanions(userId);
        if (isClosed) return;
        companions = companions.isEmpty ? null : companions;
      }
      String? constraints;
      if (userId.isNotEmpty) {
        final c = await _storage.getConstraints(userId);
        if (isClosed) return;
        constraints = c.isEmpty ? null : c;
      }
      _lastTravelTypes = travelTypes;
      _lastBudget = budget;
      _lastCompanions = companions;
      _lastConstraints = constraints;
      emit(
        CreateTripAiRecapLoaded(
          travelTypes: travelTypes.isEmpty ? 'Non renseigné' : travelTypes,
          travelStyle: travelStyle,
          budget: budget,
          companions: companions,
          constraints: constraints,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        CreateTripAiRecapLoaded(
          travelTypes: 'Non renseigné',
          travelStyle: null,
          budget: null,
          companions: null,
        ),
      );
    }
  }

  void _onSetDepartureDate(
    CreateTripAiSetDepartureDate event,
    Emitter<CreateTripAiState> emit,
  ) {
    final s = state;
    if (s is CreateTripAiRecapLoaded) {
      _lastDepartureDate = event.date;
      emit(s.copyWith(departureDate: event.date));
    }
  }

  void _onSetReturnDate(
    CreateTripAiSetReturnDate event,
    Emitter<CreateTripAiState> emit,
  ) {
    final s = state;
    if (s is CreateTripAiRecapLoaded) {
      _lastReturnDate = event.date;
      emit(s.copyWith(returnDate: event.date));
    }
  }

  Future<void> _onLaunchSearch(
    CreateTripAiLaunchSearch event,
    Emitter<CreateTripAiState> emit,
  ) async {
    // Check AI quota
    final userResult = await _authRepository.getCurrentUser();
    if (isClosed) return;
    final user = userResult.dataOrNull;
    if (user != null &&
        user.aiGenerationsRemaining != null &&
        user.aiGenerationsRemaining! <= 0) {
      emit(CreateTripAiQuotaExceeded());
      return;
    }

    int? durationDays;
    if (_lastDepartureDate != null && _lastReturnDate != null) {
      durationDays = _lastReturnDate!.difference(_lastDepartureDate!).inDays;
    }

    String? departureStr;
    String? returnStr;
    if (_lastDepartureDate != null) {
      departureStr = _lastDepartureDate!.toIso8601String().split('T')[0];
    }
    if (_lastReturnDate != null) {
      returnStr = _lastReturnDate!.toIso8601String().split('T')[0];
    }

    // Start SSE streaming
    var streaming = CreateTripAiStreaming(
      message: 'Préparation de votre voyage...',
    );
    emit(streaming);

    // Track whether we've already emitted the final summary
    CreateTripAiState? finalState;

    try {
      await emit.forEach<Map<String, dynamic>>(
        _aiRepository.planTripStream(
          travelTypes: _lastTravelTypes.isNotEmpty ? _lastTravelTypes : null,
          budgetRange: _lastBudget,
          durationDays: durationDays,
          companions: _lastCompanions,
          constraints: _lastConstraints,
          departureDate: departureStr,
          returnDate: returnStr,
        ),
        onData: (sseEvent) {
          if (finalState != null) return finalState!;

          final eventType = sseEvent['event'] as String? ?? 'message';
          final data = sseEvent['data'] as Map<String, dynamic>? ?? {};

          switch (eventType) {
            case 'progress':
              streaming = streaming.copyWith(
                phase: data['phase'] as String? ?? streaming.phase,
                message: data['message'] as String? ?? streaming.message,
              );
              return streaming;

            case 'destinations':
              final destinations = (data['destinations'] as List?)
                  ?.map((d) => Map<String, dynamic>.from(d as Map))
                  .toList();
              streaming = streaming.copyWith(destinations: destinations);
              return streaming;

            case 'activities':
              final activities = (data['activities'] as List?)
                  ?.map((a) => Map<String, dynamic>.from(a as Map))
                  .toList();
              streaming = streaming.copyWith(activities: activities);
              return streaming;

            case 'accommodations':
              final accommodations = (data['accommodations'] as List?)
                  ?.map((a) => Map<String, dynamic>.from(a as Map))
                  .toList();
              streaming = streaming.copyWith(accommodations: accommodations);
              return streaming;

            case 'baggage':
              final items = (data['items'] as List?)
                  ?.map((i) => Map<String, dynamic>.from(i as Map))
                  .toList();
              streaming = streaming.copyWith(baggageItems: items);
              return streaming;

            case 'budget':
              final estimation = data['estimation'] as Map<String, dynamic>?;
              streaming = streaming.copyWith(budgetEstimation: estimation);
              return streaming;

            case 'complete':
              final tripPlan = data['tripPlan'] as Map<String, dynamic>?;
              if (tripPlan != null) {
                _lastTripPlan = tripPlan;
                final summary = _tripPlanToSummary(tripPlan);
                finalState = CreateTripAiSummaryLoaded(summary);
                return finalState!;
              }
              return streaming;

            case 'error':
              finalState = CreateTripAiError(
                UnknownError(data['message'] as String? ?? 'Stream error'),
              );
              return finalState!;

            case 'done':
              // If we haven't received a 'complete' event, build summary
              // from accumulated streaming data
              if (finalState == null) {
                final summary = _streamingToSummary(streaming);
                finalState = CreateTripAiSummaryLoaded(summary);
                return finalState!;
              }
              return finalState!;

            default:
              return streaming;
          }
        },
        onError: (error, stackTrace) {
          return CreateTripAiError(UnknownError(error.toString()));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(CreateTripAiError(UnknownError(e.toString())));
    }
  }

  void _onSelectProposal(
    CreateTripAiSelectProposal event,
    Emitter<CreateTripAiState> emit,
  ) {
    final p = event.proposal;
    _selectedProposal = p;
    // Map the proposal (with activities) to a TripSummary
    final activities = p.activities;
    emit(
      CreateTripAiSummaryLoaded(
        TripSummary(
          destination: p.destination,
          destinationCountry: p.destinationCountry,
          durationDays: p.durationDays,
          budgetEur: p.priceEur,
          highlights: activities
              .take(4)
              .map((a) => (a['title'] ?? '') as String)
              .toList(),
          accommodation: 'À déterminer',
          dayByDayProgram: activities
              .take(p.durationDays)
              .map((a) => (a['title'] ?? '') as String)
              .toList(),
          essentialItems: const [
            'Passeport',
            'Adaptateur de voyage',
            'Crème solaire',
            'Trousse de premiers secours',
          ],
        ),
      ),
    );
  }

  Future<void> _onRegenerate(
    CreateTripAiRegenerate event,
    Emitter<CreateTripAiState> emit,
  ) async {
    _lastTripPlan = null;
    _selectedProposal = null;
    add(CreateTripAiLaunchSearch());
  }

  Future<void> _onAcceptSuggestion(
    CreateTripAiAcceptSuggestion event,
    Emitter<CreateTripAiState> emit,
  ) async {
    emit(CreateTripAiSearchLoading());

    // Build suggestion from trip plan or selected proposal
    Map<String, dynamic> suggestion;
    if (_lastTripPlan != null) {
      suggestion = _tripPlanToSuggestion(_lastTripPlan!);
    } else if (_selectedProposal != null) {
      suggestion = _selectedProposal!.toJson();
    } else {
      emit(
        CreateTripAiError(
          const UnknownError('Aucune proposition sélectionnée.'),
        ),
      );
      return;
    }

    String? startDateStr;
    String? endDateStr;
    if (_lastDepartureDate != null) {
      startDateStr = _lastDepartureDate!.toIso8601String().split('T')[0];
    }
    if (_lastReturnDate != null) {
      endDateStr = _lastReturnDate!.toIso8601String().split('T')[0];
    }

    final result = await _aiRepository.acceptInspiration(
      suggestion,
      startDate: startDateStr,
      endDate: endDateStr,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(CreateTripAiTripCreated(data));
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(CreateTripAiQuotaExceeded());
        } else {
          emit(CreateTripAiError(error));
        }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Convert a complete trip plan (from SSE 'complete' event) to TripSummary.
  TripSummary _tripPlanToSummary(Map<String, dynamic> tripPlan) {
    final dest = tripPlan['destination'] as Map<String, dynamic>? ?? {};
    final weather = tripPlan['weather'] as Map<String, dynamic>? ?? {};
    final activities =
        (tripPlan['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final accommodations =
        (tripPlan['accommodations'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final baggage =
        (tripPlan['baggage'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final budget = tripPlan['budget'] as Map<String, dynamic>? ?? {};

    // Highlights from top activities
    final highlights = activities
        .take(4)
        .map((a) => (a['title'] ?? '') as String)
        .toList();

    // Best accommodation
    String accommodationName = 'À déterminer';
    String accommodationSubtitle = '';
    double accommodationPrice = 0;
    String accommodationSource = 'estimated';
    if (accommodations.isNotEmpty) {
      final best = accommodations.first;
      accommodationName = best['name'] as String? ?? 'Hôtel';
      accommodationPrice =
          (best['price_total'] as num?)?.toDouble() ??
          (best['price_per_night'] as num?)?.toDouble() ??
          0;
      accommodationSource = best['source'] as String? ?? 'estimated';
      final currency = best['currency'] as String? ?? 'EUR';
      accommodationSubtitle =
          '${dest['city'] ?? ''} · ${accommodationPrice.toStringAsFixed(0)} $currency';
    }

    // Flight info from budget
    String flightRoute = '';
    String flightDetails = '';
    double flightPrice = 0;
    String flightSource = 'estimated';
    final flightBudget = budget['flights'] as Map<String, dynamic>?;
    if (flightBudget != null) {
      flightPrice = (flightBudget['amount'] as num?)?.toDouble() ?? 0;
      flightSource = flightBudget['source'] as String? ?? 'estimated';
      flightDetails = flightBudget['details'] as String? ?? '';
      flightRoute = '${flightBudget['details'] ?? ''}';
    }

    // Day-by-day from activities
    final dayByDay = activities
        .map((a) => (a['title'] ?? '') as String)
        .toList();
    final dayDescriptions = activities
        .map((a) => (a['description'] ?? '') as String)
        .toList();
    final dayCategories = activities
        .map((a) => (a['category'] ?? 'OTHER') as String)
        .toList();

    // Essential items from baggage
    final essentials = baggage.map((b) => (b['name'] ?? '') as String).toList();
    final essentialReasons = baggage
        .map((b) => (b['reason'] ?? '') as String)
        .toList();

    // Budget total
    final totalMin = (budget['total_min'] as num?)?.toInt() ?? 0;
    final totalMax = (budget['total_max'] as num?)?.toInt() ?? 0;
    final budgetEur = totalMax > 0 ? totalMax : totalMin;

    return TripSummary(
      destination: dest['city'] as String? ?? '',
      destinationCountry: dest['country'] as String? ?? '',
      durationDays: tripPlan['duration_days'] as int? ?? 7,
      budgetEur: budgetEur,
      highlights: highlights,
      accommodation: accommodationName,
      accommodationSubtitle: accommodationSubtitle,
      accommodationPrice: accommodationPrice,
      accommodationSource: accommodationSource,
      flightRoute: flightRoute,
      flightDetails: flightDetails,
      flightPrice: flightPrice,
      flightSource: flightSource,
      dayByDayProgram: dayByDay,
      dayByDayDescriptions: dayDescriptions,
      dayByDayCategories: dayCategories,
      essentialItems: essentials,
      essentialReasons: essentialReasons,
      budgetBreakdown: budget,
      weatherData: weather,
    );
  }

  /// Build summary from accumulated streaming state (fallback if no 'complete').
  TripSummary _streamingToSummary(CreateTripAiStreaming streaming) {
    final dest = streaming.destinations?.isNotEmpty == true
        ? streaming.destinations!.first
        : <String, dynamic>{};

    return _tripPlanToSummary({
      'destination': {
        'city': dest['city'] ?? '',
        'country': dest['country'] ?? '',
        'iata': dest['iata'] ?? '',
      },
      'weather': dest['weather'] ?? {},
      'activities': streaming.activities ?? [],
      'accommodations': streaming.accommodations ?? [],
      'baggage': streaming.baggageItems ?? [],
      'budget': streaming.budgetEstimation ?? {},
      'duration_days': _lastReturnDate != null && _lastDepartureDate != null
          ? _lastReturnDate!.difference(_lastDepartureDate!).inDays
          : 7,
    });
  }

  /// Convert trip plan to a suggestion format compatible with /ai/inspire/accept.
  Map<String, dynamic> _tripPlanToSuggestion(Map<String, dynamic> tripPlan) {
    final dest = tripPlan['destination'] as Map<String, dynamic>? ?? {};
    final activities =
        (tripPlan['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final budget = tripPlan['budget'] as Map<String, dynamic>? ?? {};

    final totalMax = (budget['total_max'] as num?)?.toInt() ?? 0;
    final totalMin = (budget['total_min'] as num?)?.toInt() ?? 0;

    return {
      'destination': dest['city'] ?? '',
      'destinationCountry': dest['country'] ?? '',
      'durationDays': tripPlan['duration_days'] ?? 7,
      'budgetEur': totalMax > 0 ? totalMax : totalMin,
      'description': 'AI-planned trip to ${dest['city'] ?? 'destination'}',
      'activities': activities
          .map(
            (a) => {
              'title': a['title'] ?? '',
              'description': a['description'] ?? '',
              'category': a['category'] ?? 'OTHER',
              'estimatedCost': a['estimated_cost'] ?? 0,
            },
          )
          .toList(),
      'matchReason': 'Planned with real-time data',
    };
  }
}
