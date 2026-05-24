import 'package:bloc/bloc.dart';

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/settings_storage.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({SettingsStorage? settingsStorage, bool autoLoad = true})
    : _storage = settingsStorage ?? getIt<SettingsStorage>(),
      super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<ChangeTheme>(_onChangeTheme);
    on<ChangeLanguage>(_onChangeLanguage);
    if (autoLoad) add(LoadSettings());
  }

  final SettingsStorage _storage;

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final theme = await _storage.getTheme();
    final language = await _storage.getLanguage();
    emit(
      state.copyWith(
        selectedTheme: theme ?? 'system',
        selectedLanguage: language ?? 'Français',
      ),
    );
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(selectedTheme: event.theme));
    await _storage.setTheme(event.theme);
  }

  Future<void> _onChangeLanguage(
    ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(selectedLanguage: event.language));
    await _storage.setLanguage(event.language);
  }
}
