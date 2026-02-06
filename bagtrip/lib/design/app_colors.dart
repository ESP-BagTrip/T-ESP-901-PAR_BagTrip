import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Semantic color layer. Use these instead of raw ColorName or Colors.xxx
/// so theme and dark mode can be adjusted in one place.
/// See ColorName for the full palette (fluttergen from assets/color/colors.xml).
class AppColors {
  AppColors._();

  // --- Surfaces (cards, scaffolds, containers) ---
  static const Color surface = ColorName.surface;
  static const Color surfaceLight = ColorName.surfaceLight;
  static const Color surfaceDark = ColorName.surfaceDark;
  static const Color surfaceVariant = ColorName.surfaceVariant;

  // --- Text on surfaces ---
  static const Color onSurface = ColorName.primaryTrueDark;
  static const Color onSurfaceAlt = ColorName.onSurface;
  static const Color onPrimary = ColorName.surface;
  static const Color hint = ColorName.hint;
  static const Color textMutedLight = ColorName.textMutedLight;

  // --- Brand ---
  static const Color primary = ColorName.primary;
  static const Color primaryDark = ColorName.primaryDark;
  static const Color primaryLight = ColorName.primaryLight;
  static const Color primarySoftLight = ColorName.primarySoftLight;
  static const Color primaryTrueDark = ColorName.primaryTrueDark;
  static const Color secondary = ColorName.secondary;
  static const Color secondaryLight = ColorName.secondaryLight;

  // --- Status ---
  static const Color success = ColorName.success;
  static const Color warning = ColorName.warning;
  static const Color warningLight = ColorName.warningLight;
  static const Color error = ColorName.error;
  static const Color errorDark = ColorName.errorDark;
  static const Color info = ColorName.info;
  static const Color infoLight = ColorName.infoLight;

  // --- Backgrounds ---
  static const Color backgroundGradientStart =
      ColorName.backgroundGradientStart;
  static const Color backgroundGradientMid = ColorName.backgroundGradientMid;
  static const Color backgroundGradientEnd = ColorName.backgroundGradientEnd;

  // --- Inputs (dark mode) ---
  static const Color inputBackgroundDark = ColorName.inputBackgroundDark;

  // --- Borders / shimmer ---
  static const Color border = ColorName.border;
  static const Color shimmerBase = ColorName.shimmerBase;
  static const Color shimmerHighlight = ColorName.shimmerHighlight;
}
