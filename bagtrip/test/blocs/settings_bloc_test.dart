import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsBloc', () {
    // ── Initial state ──────────────────────────────────────────────────

    test(
      'initial state has selectedTheme=system and selectedLanguage=Français',
      () {
        final bloc = SettingsBloc();
        expect(bloc.state.selectedTheme, 'system');
        expect(bloc.state.selectedLanguage, 'Français');
        bloc.close();
      },
    );

    // ── ChangeTheme ────────────────────────────────────────────────────

    group('ChangeTheme', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedTheme=dark when ChangeTheme(dark) is added',
        build: () => SettingsBloc(),
        act: (bloc) => bloc.add(ChangeTheme('dark')),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.selectedTheme, 'selectedTheme', 'dark')
              .having(
                (s) => s.selectedLanguage,
                'selectedLanguage',
                'Français',
              ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedTheme=light when ChangeTheme(light) is added',
        build: () => SettingsBloc(),
        act: (bloc) => bloc.add(ChangeTheme('light')),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.selectedTheme,
            'selectedTheme',
            'light',
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits two states when theme is changed twice',
        build: () => SettingsBloc(),
        act: (bloc) {
          bloc.add(ChangeTheme('dark'));
          bloc.add(ChangeTheme('light'));
        },
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.selectedTheme,
            'selectedTheme',
            'dark',
          ),
          isA<SettingsState>().having(
            (s) => s.selectedTheme,
            'selectedTheme',
            'light',
          ),
        ],
      );
    });

    // ── ChangeLanguage ─────────────────────────────────────────────────

    group('ChangeLanguage', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedLanguage=English when ChangeLanguage(English) is added',
        build: () => SettingsBloc(),
        act: (bloc) => bloc.add(ChangeLanguage('English')),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.selectedLanguage, 'selectedLanguage', 'English')
              .having((s) => s.selectedTheme, 'selectedTheme', 'system'),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedLanguage=Español when ChangeLanguage(Español) is added',
        build: () => SettingsBloc(),
        act: (bloc) => bloc.add(ChangeLanguage('Español')),
        expect: () => [
          isA<SettingsState>().having(
            (s) => s.selectedLanguage,
            'selectedLanguage',
            'Español',
          ),
        ],
      );
    });

    // ── Combined ChangeTheme + ChangeLanguage ──────────────────────────

    group('Combined changes', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits correct states when theme and language are changed in sequence',
        build: () => SettingsBloc(),
        act: (bloc) {
          bloc.add(ChangeTheme('dark'));
          bloc.add(ChangeLanguage('English'));
        },
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.selectedTheme, 'selectedTheme', 'dark')
              .having(
                (s) => s.selectedLanguage,
                'selectedLanguage',
                'Français',
              ),
          isA<SettingsState>()
              .having((s) => s.selectedTheme, 'selectedTheme', 'dark')
              .having((s) => s.selectedLanguage, 'selectedLanguage', 'English'),
        ],
      );
    });
  });
}
