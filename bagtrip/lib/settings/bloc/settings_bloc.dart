import 'package:bloc/bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  void _onChangeTheme(ChangeTheme event, Emitter<SettingsState> emit) {
    emit(state.copyWith(selectedTheme: event.theme));
  }

  void _onChangeLanguage(ChangeLanguage event, Emitter<SettingsState> emit) {
    emit(state.copyWith(selectedLanguage: event.language));
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
