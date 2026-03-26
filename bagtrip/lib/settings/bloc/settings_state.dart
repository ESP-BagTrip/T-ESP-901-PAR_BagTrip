part of 'settings_bloc.dart';

final class SettingsState {
  final String selectedTheme;
  final String selectedLanguage;

  const SettingsState({
    this.selectedTheme = 'system',
    this.selectedLanguage = 'Français',
  });

  SettingsState copyWith({String? selectedTheme, String? selectedLanguage}) {
    return SettingsState(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }
}
