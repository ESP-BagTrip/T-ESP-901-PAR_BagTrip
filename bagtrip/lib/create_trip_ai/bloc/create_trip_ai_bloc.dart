import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/utils/error_display.dart';
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

  Future<void> _onLoadRecap(
    CreateTripAiLoadRecap event,
    Emitter<CreateTripAiState> emit,
  ) async {
    emit(CreateTripAiRecapLoading());
    try {
      final userResult = await _authRepository.getCurrentUser();
      final userId = userResult.dataOrNull?.id ?? '';
      String travelTypes = '';
      String? travelStyle;
      String? budget;
      String? companions;
      if (userId.isNotEmpty) {
        travelTypes = await _storage.getTravelTypes(userId);
        travelStyle = await _storage.getTravelStyle(userId);
        final b = await _storage.getBudget(userId);
        travelStyle = travelStyle.isEmpty ? null : travelStyle;
        budget = b.isEmpty ? null : b;
        companions = await _storage.getCompanions(userId);
        companions = companions.isEmpty ? null : companions;
      }
      String? constraints;
      if (userId.isNotEmpty) {
        final c = await _storage.getConstraints(userId);
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
    emit(CreateTripAiSearchLoading());

    // Check AI quota
    final userResult = await _authRepository.getCurrentUser();
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
    // Guess season from departure date
    String? season;
    if (_lastDepartureDate != null) {
      final month = _lastDepartureDate!.month;
      if (month >= 3 && month <= 5) {
        season = 'printemps';
      } else if (month >= 6 && month <= 8) {
        season = 'été';
      } else if (month >= 9 && month <= 11) {
        season = 'automne';
      } else {
        season = 'hiver';
      }
    }

    final result = await _aiRepository.getInspiration(
      travelTypes: _lastTravelTypes.isNotEmpty ? _lastTravelTypes : null,
      budgetRange: _lastBudget,
      durationDays: durationDays,
      companions: _lastCompanions,
      season: season,
      constraints: _lastConstraints,
    );
    switch (result) {
      case Success(:final data):
        final proposals = data.asMap().entries.map((entry) {
          return AiTripProposal.fromJsonWithId(entry.value, id: '${entry.key}');
        }).toList();
        emit(CreateTripAiResultsLoaded(proposals));
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(CreateTripAiQuotaExceeded());
        } else {
          emit(CreateTripAiError(toUserFriendlyMessage(error)));
        }
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
    // Re-run the same search
    add(CreateTripAiLaunchSearch());
  }

  Future<void> _onAcceptSuggestion(
    CreateTripAiAcceptSuggestion event,
    Emitter<CreateTripAiState> emit,
  ) async {
    if (_selectedProposal == null) {
      emit(CreateTripAiError('Aucune proposition sélectionnée.'));
      return;
    }
    emit(CreateTripAiSearchLoading());

    String? startDateStr;
    String? endDateStr;
    if (_lastDepartureDate != null) {
      startDateStr = _lastDepartureDate!.toIso8601String().split('T')[0];
    }
    if (_lastReturnDate != null) {
      endDateStr = _lastReturnDate!.toIso8601String().split('T')[0];
    }

    final result = await _aiRepository.acceptInspiration(
      _selectedProposal!.toJson(),
      startDate: startDateStr,
      endDate: endDateStr,
    );
    switch (result) {
      case Success(:final data):
        emit(CreateTripAiTripCreated(data));
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(CreateTripAiQuotaExceeded());
        } else {
          emit(CreateTripAiError(toUserFriendlyMessage(error)));
        }
    }
  }
}
