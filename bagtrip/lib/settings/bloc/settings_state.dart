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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          selectedTheme == other.selectedTheme &&
          selectedLanguage == other.selectedLanguage;

  @override
  int get hashCode => Object.hash(selectedTheme, selectedLanguage);
}
