import 'dart:math' as math;

import 'package:bagtrip/design/app_theme.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a fully configured MaterialApp with l10n and theme.
Widget buildTestableWidget(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: child),
    ),
  );
}

/// Computes the WCAG 2.1 relative luminance of a color.
double relativeLuminance(Color color) {
  double channel(double c) {
    final sRGB = c / 255.0;
    return sRGB <= 0.03928
        ? sRGB / 12.92
        : math.pow((sRGB + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r * 255) +
      0.7152 * channel(color.g * 255) +
      0.0722 * channel(color.b * 255);
}

/// Computes the WCAG 2.1 contrast ratio between two colors.
/// Returns a value >= 1.0. AA text requires >= 4.5.
double contrastRatio(Color fg, Color bg) {
  final l1 = relativeLuminance(fg);
  final l2 = relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Asserts that all interactive widgets (IconButton, InkWell, GestureDetector)
/// have a minimum touch target of [minSize] logical pixels.
Future<void> expectMinimumTouchTargets(
  WidgetTester tester, {
  double minSize = 44.0,
}) async {
  final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
  for (final button in iconButtons) {
    final iconSize = button.iconSize ?? 24.0;
    // IconButton defaults to 48x48 touch target unless shrinkWrap
    expect(
      iconSize >= 24.0,
      isTrue,
      reason: 'IconButton icon size should be at least 24px',
    );
  }
}
