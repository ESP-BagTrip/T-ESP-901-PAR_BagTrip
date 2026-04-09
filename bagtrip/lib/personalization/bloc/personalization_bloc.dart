import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'personalization_event.dart';
part 'personalization_state.dart';

/// Welcome = 0, then 5 content steps: companions, budget, interests, frequency, constraints.
const int _kTotalSteps = 6;

class PersonalizationBloc
    extends Bloc<PersonalizationEvent, PersonalizationState> {
  PersonalizationBloc({
    AuthRepository? authRepository,
    PersonalizationStorage? personalizationStorage,
    ProfileRepository? profileRepository,
  }) : _authRepository = authRepository ?? getIt<AuthRepository>(),
       _storage = personalizationStorage ?? getIt<PersonalizationStorage>(),
       _profileRepository = profileRepository ?? getIt<ProfileRepository>(),
       super(PersonalizationInitial()) {
    on<LoadPersonalization>(_onLoadPersonalization);
    on<SetTravelTypes>(_onSetTravelTypes);
    on<SetTravelStyle>(_onSetTravelStyle);
    on<SetBudget>(_onSetBudget);
    on<SetCompanions>(_onSetCompanions);
    on<SetTravelFrequency>(_onSetTravelFrequency);
    on<SetConstraints>(_onSetConstraints);
    on<PersonalizationNextStep>(_onNextStep);
    on<PersonalizationPreviousStep>(_onPreviousStep);
    on<SkipPersonalization>(_onSkipPersonalization);
    on<SaveAndFinishPersonalization>(_onSaveAndFinish);
  }

  final AuthRepository _authRepository;
  final PersonalizationStorage _storage;
  final ProfileRepository _profileRepository;

  Future<void> _onLoadPersonalization(
    LoadPersonalization event,
    Emitter<PersonalizationState> emit,
  ) async {
    emit(PersonalizationLoading());
    try {
      final userResult = await _authRepository.getCurrentUser();
      if (isClosed) return;
      final user = userResult.dataOrNull;
      if (user == null || user.id.isEmpty) {
        emit(PersonalizationInitial());
        return;
      }

      // Try loading from API first
      Set<String> selectedTypes = {};
      String? style;
      String? budget;
      String? companions;
      String? travelFrequency;
      String? constraints;

      final profileResult = await _profileRepository.getProfile();
      if (isClosed) return;
      if (profileResult is Success) {
        final profile = (profileResult as Success).data;
        selectedTypes = profile.travelTypes.toSet();
        style = profile.travelStyle;
        budget = profile.budget;
        companions = profile.companions;
        travelFrequency = profile.travelFrequency;
        constraints = profile.medicalConstraints;
      } else {
        // Fallback to local storage
        final typesStr = await _storage.getTravelTypes(user.id);
        if (isClosed) return;
        final localStyle = await _storage.getTravelStyle(user.id);
        if (isClosed) return;
        final localBudget = await _storage.getBudget(user.id);
        if (isClosed) return;
        final localCompanions = await _storage.getCompanions(user.id);
        if (isClosed) return;
        selectedTypes = typesStr.isNotEmpty
            ? typesStr.split(',').toSet()
            : <String>{};
        style = localStyle.isEmpty ? null : localStyle;
        budget = localBudget.isEmpty ? null : localBudget;
        companions = localCompanions.isEmpty ? null : localCompanions;
      }
      // Fallback to local storage for fields not yet populated from API
      if (travelFrequency == null || travelFrequency.isEmpty) {
        final freq = await _storage.getTravelFrequency(user.id);
        if (isClosed) return;
        travelFrequency = freq.isEmpty ? null : freq;
      }
      if (constraints == null || constraints.isEmpty) {
        final constr = await _storage.getConstraints(user.id);
        if (isClosed) return;
        constraints = constr.isEmpty ? null : constr;
      }

      final welcomeSeen = await _storage.hasSeenPersonalizationWelcome(user.id);
      if (isClosed) return;
      final hasExistingPreferences =
          selectedTypes.isNotEmpty ||
          budget != null ||
          companions != null ||
          (travelFrequency != null && travelFrequency.isNotEmpty);
      final showWelcome = !welcomeSeen && !hasExistingPreferences;

      emit(
        PersonalizationLoaded(
          step: showWelcome ? 0 : 1,
          userId: user.id,
          selectedTravelTypes: selectedTypes,
          travelStyle: style,
          budget: budget,
          companions: companions,
          travelFrequency: travelFrequency,
          constraints: constraints,
        ),
      );
    } catch (_) {
      if (isClosed) return;
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

  void _onSetTravelFrequency(
    SetTravelFrequency event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(travelFrequency: event.value));
  }

  void _onSetConstraints(
    SetConstraints event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    emit(current.copyWith(constraints: event.value));
  }

  Future<void> _onNextStep(
    PersonalizationNextStep event,
    Emitter<PersonalizationState> emit,
  ) async {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    if (current.step < _kTotalSteps - 1) {
      if (current.step == 0) {
        await _storage.setPersonalizationWelcomeSeen(current.userId);
        if (isClosed) return;
      }
      emit(current.copyWith(step: current.step + 1));
    }
  }

  void _onPreviousStep(
    PersonalizationPreviousStep event,
    Emitter<PersonalizationState> emit,
  ) {
    final current = state;
    if (current is! PersonalizationLoaded) return;
    if (current.step > 0) {
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
      if (isClosed) return;
      if (current is PersonalizationLoaded && current.step == 0) {
        await _storage.setPersonalizationWelcomeSeen(userId);
        if (isClosed) return;
      }
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
    if (isClosed) return;
    if (current.travelStyle != null) {
      await _storage.setTravelStyle(userId, current.travelStyle!);
      if (isClosed) return;
    }
    if (current.budget != null) {
      await _storage.setBudget(userId, current.budget!);
      if (isClosed) return;
    }
    if (current.companions != null) {
      await _storage.setCompanions(userId, current.companions!);
      if (isClosed) return;
    }
    if (current.travelFrequency != null) {
      await _storage.setTravelFrequency(userId, current.travelFrequency!);
      if (isClosed) return;
    }
    if (current.constraints != null) {
      await _storage.setConstraints(userId, current.constraints!);
      if (isClosed) return;
    }
    await _storage.setPersonalizationPromptSeen(userId);
    if (isClosed) return;
    await _storage.setPersonalizationWelcomeSeen(userId);
    if (isClosed) return;

    // Persist to backend (best effort)
    await _profileRepository.updateProfile(
      travelTypes: current.selectedTravelTypes.toList(),
      travelStyle: current.travelStyle ?? 'flexible',
      budget: current.budget,
      companions: current.companions,
      travelFrequency: current.travelFrequency,
      medicalConstraints: current.constraints,
    );
    if (isClosed) return;

    emit(PersonalizationCompleted());
  }
}
