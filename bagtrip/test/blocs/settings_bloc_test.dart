import 'package:bagtrip/service/settings_storage.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsStorage extends Mock implements SettingsStorage {}

void main() {
  late MockSettingsStorage mockStorage;

  setUp(() {
    mockStorage = MockSettingsStorage();
    when(() => mockStorage.getTheme()).thenAnswer((_) async => null);
    when(() => mockStorage.getLanguage()).thenAnswer((_) async => null);
    when(() => mockStorage.setTheme(any())).thenAnswer((_) async {});
    when(() => mockStorage.setLanguage(any())).thenAnswer((_) async {});
  });

  SettingsBloc buildBloc() =>
      SettingsBloc(settingsStorage: mockStorage, autoLoad: false);

  group('SettingsBloc', () {
    // ── Initial state ──────────────────────────────────────────────────

    test(
      'initial state has selectedTheme=system and selectedLanguage=Français',
      () {
        final bloc = buildBloc();
        expect(bloc.state.selectedTheme, 'system');
        expect(bloc.state.selectedLanguage, 'Français');
        bloc.close();
      },
    );

    // ── LoadSettings ──────────────────────────────────────────────────

    blocTest<SettingsBloc, SettingsState>(
      'loads persisted theme and language from storage',
      setUp: () {
        when(() => mockStorage.getTheme()).thenAnswer((_) async => 'dark');
        when(
          () => mockStorage.getLanguage(),
        ).thenAnswer((_) async => 'English');
      },
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.selectedTheme, 'selectedTheme', 'dark')
            .having((s) => s.selectedLanguage, 'selectedLanguage', 'English'),
      ],
      verify: (_) {
        verify(() => mockStorage.getTheme()).called(1);
        verify(() => mockStorage.getLanguage()).called(1);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'defaults to system/Français when storage returns null',
      build: buildBloc,
      act: (bloc) => bloc.add(LoadSettings()),
      expect: () => [
        isA<SettingsState>()
            .having((s) => s.selectedTheme, 'selectedTheme', 'system')
            .having((s) => s.selectedLanguage, 'selectedLanguage', 'Français'),
      ],
    );

    // ── ChangeTheme ────────────────────────────────────────────────────

    group('ChangeTheme', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedTheme=dark when ChangeTheme(dark) is added',
        build: buildBloc,
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
        verify: (_) {
          verify(() => mockStorage.setTheme('dark')).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedTheme=light when ChangeTheme(light) is added',
        build: buildBloc,
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
        build: buildBloc,
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
        build: buildBloc,
        act: (bloc) => bloc.add(ChangeLanguage('English')),
        expect: () => [
          isA<SettingsState>()
              .having((s) => s.selectedLanguage, 'selectedLanguage', 'English')
              .having((s) => s.selectedTheme, 'selectedTheme', 'system'),
        ],
        verify: (_) {
          verify(() => mockStorage.setLanguage('English')).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsState with selectedLanguage=Español when ChangeLanguage(Español) is added',
        build: buildBloc,
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
        build: buildBloc,
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
