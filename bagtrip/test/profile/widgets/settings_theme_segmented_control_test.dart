import 'package:bagtrip/profile/widgets/settings/settings_theme_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_widget.dart';

void main() {
  group('SettingsThemeSegmentedControl', () {
    testWidgets('calls onThemeChanged when tapping dark segment', (
      tester,
    ) async {
      var selected = 'light';
      await pumpLocalized(
        tester,
        SizedBox(
          width: 360,
          child: SettingsThemeSegmentedControl(
            selectedTheme: selected,
            lightLabel: 'Light',
            darkLabel: 'Dark',
            systemLabel: 'System',
            onThemeChanged: (v) => selected = v,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Dark'));
      await tester.pump();

      expect(selected, 'dark');
    });

    testWidgets('shows system segment selected', (tester) async {
      await pumpLocalized(
        tester,
        const SizedBox(
          width: 360,
          child: SettingsThemeSegmentedControl(
            selectedTheme: 'system',
            lightLabel: 'Light',
            darkLabel: 'Dark',
            systemLabel: 'System',
            onThemeChanged: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.byType(SettingsThemeSegmentedControl), findsOneWidget);
    });
  });
}

void _noop(String _) {}
