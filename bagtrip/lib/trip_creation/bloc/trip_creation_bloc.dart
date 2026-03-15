import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/create_trip_ai/models/ai_trip_proposal.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'trip_creation_event.dart';
part 'trip_creation_state.dart';

class TripCreationBloc extends Bloc<TripCreationEvent, TripCreationState> {
  final LocationService _locationService;
  final TripRepository _tripRepository;
  final AiRepository _aiRepository;
  final AuthRepository _authRepository;
  final PersonalizationStorage _storage;

  TripCreationBloc({
    LocationService? locationService,
    TripRepository? tripRepository,
    AiRepository? aiRepository,
    AuthRepository? authRepository,
    PersonalizationStorage? personalizationStorage,
  }) : _locationService = locationService ?? getIt<LocationService>(),
       _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _aiRepository = aiRepository ?? getIt<AiRepository>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       _storage = personalizationStorage ?? getIt<PersonalizationStorage>(),
       super(const TripCreationState()) {
    on<GoToStep>(_onGoToStep);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<SearchDestination>(_onSearchDestination);
    on<SelectDestination>(_onSelectDestination);
    on<ClearDestination>(_onClearDestination);
    on<LaunchInspireMe>(_onLaunchInspireMe);
    on<SelectAiSuggestion>(_onSelectAiSuggestion);
    on<SetDates>(_onSetDates);
    on<SetTravelers>(_onSetTravelers);
    on<CreateTripFromFlow>(_onCreateTrip);
  }

  void _onGoToStep(GoToStep event, Emitter<TripCreationState> emit) {
    if (event.step >= 0 && event.step <= 3) {
      emit(state.copyWith(currentStep: event.step, clearError: true));
    }
  }

  void _onNextStep(NextStep event, Emitter<TripCreationState> emit) {
    if (state.currentStep < 3) {
      emit(
        state.copyWith(currentStep: state.currentStep + 1, clearError: true),
      );
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<TripCreationState> emit) {
    if (state.currentStep > 0) {
      emit(
        state.copyWith(currentStep: state.currentStep - 1, clearError: true),
      );
    }
  }

  Future<void> _onSearchDestination(
    SearchDestination event,
    Emitter<TripCreationState> emit,
  ) async {
    if (event.keyword.length < 2) {
      emit(state.copyWith(clearLocationResults: true));
      return;
    }
    emit(state.copyWith(isLoadingLocations: true, clearError: true));
    try {
      final results = await _locationService.searchLocationsByKeyword(
        event.keyword,
        'CITY,AIRPORT',
      );
      if (isClosed) return;
      emit(state.copyWith(isLoadingLocations: false, locationResults: results));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingLocations: false, error: e.toString()));
    }
  }

  void _onSelectDestination(
    SelectDestination event,
    Emitter<TripCreationState> emit,
  ) {
    emit(
      state.copyWith(
        destinationName: event.name,
        destinationIata: event.iata,
        destinationCountry: event.country,
        clearLocationResults: true,
        clearSelectedAi: true,
      ),
    );
  }

  void _onClearDestination(
    ClearDestination event,
    Emitter<TripCreationState> emit,
  ) {
    emit(
      state.copyWith(
        clearDestination: true,
        clearLocationResults: true,
        clearSelectedAi: true,
      ),
    );
  }

  Future<void> _onLaunchInspireMe(
    LaunchInspireMe event,
    Emitter<TripCreationState> emit,
  ) async {
    emit(state.copyWith(isLoadingAi: true, clearError: true));

    try {
      final userResult = await _authRepository.getCurrentUser();
      if (isClosed) return;
      final user = userResult.dataOrNull;
      final userId = user?.id ?? '';

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

      int? durationDays;
      if (state.startDate != null && state.endDate != null) {
        durationDays = state.endDate!.difference(state.startDate!).inDays;
      }

      String? season;
      if (state.startDate != null) {
        final month = state.startDate!.month;
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
        travelTypes: travelTypes,
        budgetRange: budget,
        durationDays: durationDays,
        companions: companions,
        season: season,
        constraints: constraints,
      );
      if (isClosed) return;

      switch (result) {
        case Success(:final data):
          final proposals = data.asMap().entries.map((entry) {
            return AiTripProposal.fromJsonWithId(
              entry.value,
              id: '${entry.key}',
            );
          }).toList();
          emit(state.copyWith(isLoadingAi: false, aiSuggestions: proposals));
        case Failure(:final error):
          emit(state.copyWith(isLoadingAi: false, error: error.toString()));
      }
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoadingAi: false, error: e.toString()));
    }
  }

  void _onSelectAiSuggestion(
    SelectAiSuggestion event,
    Emitter<TripCreationState> emit,
  ) {
    final p = event.proposal;
    emit(
      state.copyWith(
        destinationName: p.destination,
        destinationCountry: p.destinationCountry,
        selectedAiProposal: p,
        clearLocationResults: true,
      ),
    );
  }

  void _onSetDates(SetDates event, Emitter<TripCreationState> emit) {
    emit(state.copyWith(startDate: event.start, endDate: event.end));
  }

  void _onSetTravelers(SetTravelers event, Emitter<TripCreationState> emit) {
    emit(state.copyWith(nbTravelers: event.count));
  }

  Future<void> _onCreateTrip(
    CreateTripFromFlow event,
    Emitter<TripCreationState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, clearError: true));

    // If AI suggestion selected, use acceptInspiration
    if (state.selectedAiProposal != null) {
      String? startDateStr;
      String? endDateStr;
      if (state.startDate != null) {
        startDateStr = state.startDate!.toIso8601String().split('T')[0];
      }
      if (state.endDate != null) {
        endDateStr = state.endDate!.toIso8601String().split('T')[0];
      }

      final result = await _aiRepository.acceptInspiration(
        state.selectedAiProposal!.toJson(),
        startDate: startDateStr,
        endDate: endDateStr,
      );
      if (isClosed) return;
      switch (result) {
        case Success(:final data):
          final tripId =
              data['id']?.toString() ?? data['tripId']?.toString() ?? '';
          emit(state.copyWith(isCreating: false, createdTripId: tripId));
        case Failure(:final error):
          emit(state.copyWith(isCreating: false, error: error.toString()));
      }
      return;
    }

    // Manual creation
    final title = state.destinationName ?? 'Mon voyage';
    final result = await _tripRepository.createTrip(
      title: title,
      destinationName: state.destinationName,
      destinationIata: state.destinationIata,
      startDate: state.startDate,
      endDate: state.endDate,
      nbTravelers: state.nbTravelers,
    );
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(isCreating: false, createdTripId: data.id));
      case Failure(:final error):
        emit(state.copyWith(isCreating: false, error: error.toString()));
    }
  }
}
