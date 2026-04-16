// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/profile/widgets/preferences_section.dart';
import 'package:bagtrip/settings/bloc/settings_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_widget.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

void main() {
  late _MockSettingsBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(LoadSettings());
    registerFallbackValue(const SettingsState());
  });

  setUp(() {
    mockBloc = _MockSettingsBloc();
  });

  Future<void> pump(WidgetTester tester, SettingsState seed) async {
    when(() => mockBloc.state).thenReturn(seed);
    whenListen(
      mockBloc,
      const Stream<SettingsState>.empty(),
      initialState: seed,
    );
    await pumpLocalized(
      tester,
      SizedBox(
        width: 800,
        height: 600,
        child: BlocProvider<SettingsBloc>.value(
          value: mockBloc,
          child: const PreferencesSection(),
        ),
      ),
    );
    await tester.pump();
  }

  group('PreferencesSection', () {
    testWidgets('renders with default settings state', (tester) async {
      await pump(tester, const SettingsState());
      expect(find.byType(PreferencesSection), findsOneWidget);
    });

    testWidgets('renders with light theme selected', (tester) async {
      await pump(
        tester,
        const SettingsState(
          selectedTheme: 'light',
          selectedLanguage: 'English',
        ),
      );
      expect(find.byType(PreferencesSection), findsOneWidget);
    });

    testWidgets('renders with dark theme selected', (tester) async {
      await pump(
        tester,
        const SettingsState(
          selectedTheme: 'dark',
          selectedLanguage: 'Français',
        ),
      );
      expect(find.byType(PreferencesSection), findsOneWidget);
    });

    testWidgets('renders with system theme selected', (tester) async {
      await pump(
        tester,
        const SettingsState(
          selectedTheme: 'system',
          selectedLanguage: 'Français',
        ),
      );
      expect(find.byType(PreferencesSection), findsOneWidget);
    });

    testWidgets('renders with English language', (tester) async {
      await pump(
        tester,
        const SettingsState(
          selectedTheme: 'light',
          selectedLanguage: 'English',
        ),
      );
      expect(find.byType(PreferencesSection), findsOneWidget);
    });
  });
}
