import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/service/profile_api_service.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'personalization_event.dart';
part 'personalization_state.dart';

const int _kTotalSteps = 4;

class PersonalizationBloc
    extends Bloc<PersonalizationEvent, PersonalizationState> {
  PersonalizationBloc({
    AuthService? authService,
    PersonalizationStorage? personalizationStorage,
    ProfileApiService? profileApiService,
  }) : _authService = authService ?? AuthService(),
       _storage = personalizationStorage ?? PersonalizationStorage(),
       _profileApi = profileApiService ?? ProfileApiService(),
       super(PersonalizationInitial()) {
    on<LoadPersonalization>(_onLoadPersonalization);
    on<SetTravelTypes>(_onSetTravelTypes);
    on<SetTravelStyle>(_onSetTravelStyle);
    on<SetBudget>(_onSetBudget);
    on<SetCompanions>(_onSetCompanions);
    on<PersonalizationNextStep>(_onNextStep);
    on<PersonalizationPreviousStep>(_onPreviousStep);
    on<SkipPersonalization>(_onSkipPersonalization);
    on<SaveAndFinishPersonalization>(_onSaveAndFinish);
  }

  final AuthService _authService;
  final PersonalizationStorage _storage;
  final ProfileApiService _profileApi;

  Future<void> _onLoadPersonalization(
    LoadPersonalization event,
    Emitter<PersonalizationState> emit,
  ) async {
    emit(PersonalizationLoading());
    try {
      final user = await _authService.getCurrentUser();
      if (user == null || user.id.isEmpty) {
        emit(PersonalizationInitial());
        return;
      }

      // Try loading from API first
      Set<String> selectedTypes = {};
      String? style;
      String? budget;
      String? companions;

      try {
        final profile = await _profileApi.getProfile();
        selectedTypes = profile.travelTypes.toSet();
        style = profile.travelStyle;
        budget = profile.budget;
        companions = profile.companions;
      } catch (_) {
        // Fallback to local storage
        final typesStr = await _storage.getTravelTypes(user.id);
        final localStyle = await _storage.getTravelStyle(user.id);
        final localBudget = await _storage.getBudget(user.id);
        final localCompanions = await _storage.getCompanions(user.id);
        selectedTypes =
            typesStr.isNotEmpty ? typesStr.split(',').toSet() : <String>{};
        style = localStyle.isEmpty ? null : localStyle;
        budget = localBudget.isEmpty ? null : localBudget;
        companions = localCompanions.isEmpty ? null : localCompanions;
      }

      emit(
        PersonalizationLoaded(
          step: 1,
          userId: user.id,
          selectedTravelTypes: selectedTypes,
          travelStyle: style,
          budget: budget,
          companions: companions,
        ),
      );
    } catch (_) {
      emit(PersonalizationInitial());
    }
  }

  void _onSetTravelTypes(
    SetTravelTypes event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(selectedTravelTypes: event.value));
  }

  void _onSetTravelStyle(
    SetTravelStyle event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(travelStyle: event.value));
  }

  void _onSetBudget(SetBudget event, Emitter<PersonalizationState> emit) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(budget: event.value));
  }

  void _onSetCompanions(
    SetCompanions event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(companions: event.value));
  }

  void _onNextStep(
    PersonalizationNextStep event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    if (current.step < _kTotalSteps) {
      emit(current.copyWith(step: current.step + 1));
    }
  }

  void _onPreviousStep(
    PersonalizationPreviousStep event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    if (current.step > 1) {
      emit(current.copyWith(step: current.step - 1));
    }
  }

  Future<void> _onSkipPersonalization(
    SkipPersonalization event,
    Emitter<PersonalizationState> emit,
  ) async {
    final current = state;
    final userId = current is PersonalizationLoaded ? current.userId : null;
    if (userId != null && userId.isNotEmpty) {
      await _storage.setPersonalizationPromptSeen(userId);
    }
    emit(PersonalizationSkipped());
  }

  Future<void> _onSaveAndFinish(
    SaveAndFinishPersonalization event,
    Emitter<PersonalizationState> emit,
  ) async {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    final userId = current.userId;
    if (userId.isEmpty) {
      emit(PersonalizationSkipped());
      return;
    }

    // Save to local storage
    await _storage.setTravelTypes(
      userId,
      current.selectedTravelTypes.join(','),
    );
    if (current.travelStyle != null) {
      await _storage.setTravelStyle(userId, current.travelStyle!);
    }
    if (current.budget != null) {
      await _storage.setBudget(userId, current.budget!);
    }
    if (current.companions != null) {
      await _storage.setCompanions(userId, current.companions!);
    }
    await _storage.setPersonalizationPromptSeen(userId);

    // Persist to backend (best effort)
    try {
      await _profileApi.updateProfile(
        travelTypes: current.selectedTravelTypes.toList(),
        travelStyle: current.travelStyle,
        budget: current.budget,
        companions: current.companions,
      );
    } catch (_) {
      // Best effort — local storage is the fallback
    }

    emit(PersonalizationCompleted());
  }
}
