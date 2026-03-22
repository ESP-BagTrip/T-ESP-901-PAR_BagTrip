import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed surface size for deterministic golden rendering across platforms.
const goldenSurfaceSize = Size(400, 800);

/// Wraps [child] in a [MaterialApp] with light theme, EN locale,
/// and localization delegates — ready for golden comparison.
Widget goldenWrapper(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Sets the surface size before a golden test and resets it after.
Future<void> setGoldenSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(goldenSurfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
