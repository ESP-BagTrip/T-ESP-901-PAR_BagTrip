import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/create_trip_ai/models/trip_summary.dart';
import 'package:bagtrip/service/ai_service.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

part 'create_trip_ai_event.dart';
part 'create_trip_ai_state.dart';

class CreateTripAiBloc extends Bloc<CreateTripAiEvent, CreateTripAiState> {
  CreateTripAiBloc({
    AuthService? authService,
    PersonalizationStorage? personalizationStorage,
    AiService? aiService,
  }) : _authService = authService ?? AuthService(),
       _storage = personalizationStorage ?? PersonalizationStorage(),
       _aiService = aiService ?? AiService(),
       super(CreateTripAiInitial()) {
    on<CreateTripAiLoadRecap>(_onLoadRecap);
    on<CreateTripAiSetDepartureDate>(_onSetDepartureDate);
    on<CreateTripAiSetReturnDate>(_onSetReturnDate);
    on<CreateTripAiLaunchSearch>(_onLaunchSearch);
    on<CreateTripAiSelectProposal>(_onSelectProposal);
    on<CreateTripAiRegenerate>(_onRegenerate);
    on<CreateTripAiAcceptSuggestion>(_onAcceptSuggestion);
  }

  final AuthService _authService;
  final PersonalizationStorage _storage;
  final AiService _aiService;

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
      final user = await _authService.getCurrentUser();
      final userId = user?.id ?? '';
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
    try {
      // Check AI quota
      final user = await _authService.getCurrentUser();
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

      final results = await _aiService.getInspiration(
        travelTypes: _lastTravelTypes.isNotEmpty ? _lastTravelTypes : null,
        budgetRange: _lastBudget,
        durationDays: durationDays,
        companions: _lastCompanions,
        season: season,
        constraints: _lastConstraints,
      );

      final proposals =
          results.asMap().entries.map((entry) {
            return AiTripProposal.fromJson(entry.value, id: '${entry.key}');
          }).toList();

      emit(CreateTripAiResultsLoaded(proposals));
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        emit(CreateTripAiQuotaExceeded());
      } else {
        emit(CreateTripAiError(toUserFriendlyMessage(e)));
      }
    } catch (e) {
      emit(CreateTripAiError(toUserFriendlyMessage(e)));
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
          highlights:
              activities
                  .take(4)
                  .map((a) => (a['title'] ?? '') as String)
                  .toList(),
          accommodation: 'À déterminer',
          dayByDayProgram:
              activities
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
    try {
      String? startDateStr;
      String? endDateStr;
      if (_lastDepartureDate != null) {
        startDateStr = _lastDepartureDate!.toIso8601String().split('T')[0];
      }
      if (_lastReturnDate != null) {
        endDateStr = _lastReturnDate!.toIso8601String().split('T')[0];
      }
      final tripData = await _aiService.acceptInspiration(
        _selectedProposal!.toJson(),
        startDate: startDateStr,
        endDate: endDateStr,
      );
      emit(CreateTripAiTripCreated(tripData));
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        emit(CreateTripAiQuotaExceeded());
      } else {
        emit(CreateTripAiError(toUserFriendlyMessage(e)));
      }
    } catch (e) {
      emit(CreateTripAiError(toUserFriendlyMessage(e)));
    }
  }
}
