import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
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
  }) : _authService = authService ?? AuthService(),
       _storage = personalizationStorage ?? PersonalizationStorage(),
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
      final typesStr = await _storage.getTravelTypes(user.id);
      final style = await _storage.getTravelStyle(user.id);
      final budget = await _storage.getBudget(user.id);
      final companions = await _storage.getCompanions(user.id);
      final selectedTypes =
          typesStr.isNotEmpty ? typesStr.split(',').toSet() : <String>{};
      emit(
        PersonalizationLoaded(
          step: 1,
          userId: user.id,
          selectedTravelTypes: selectedTypes,
          travelStyle: style.isEmpty ? null : style,
          budget: budget.isEmpty ? null : budget,
          companions: companions.isEmpty ? null : companions,
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
    emit(PersonalizationCompleted());
  }
}
