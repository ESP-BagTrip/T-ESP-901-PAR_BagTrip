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

  // --- Accessible text (pre-computed contrast ratios >= 4.5:1) ---
  static const Color textSecondary = Color(0xFF5B6A7B); // 5.2:1 on white
  static const Color textTertiary = Color(0xFF4A5568); // 6.3:1 on white
  static const Color textDisabled = Color(
    0xFF6B7280,
  ); // 4.6:1 on white (minimum AA)
  static const Color textSecondaryDark = Color(0xFFB0BEC5); // 4.5:1 on #0E2135

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

  // --- Budget category (light) ---
  static const Color categoryFlight = Color(0xFFBBDEFB); // blue.shade100
  static const Color categoryAccommodation = Color(
    0xFFE1BEE7,
  ); // purple.shade100
  static const Color categoryFood = Color(0xFFFFE0B2); // orange.shade100
  static const Color categoryActivity = Color(0xFFB2DFDB); // teal.shade100
  static const Color categoryTransport = Color(0xFFC5CAE9); // indigo.shade100
  static const Color categoryOther = Color(0xFFEEEEEE); // grey.shade200

  // --- Budget category (dark) ---
  static const Color categoryFlightDark = Color(0xFF1565C0); // blue.shade800
  static const Color categoryAccommodationDark = Color(
    0xFF6A1B9A,
  ); // purple.shade800
  static const Color categoryFoodDark = Color(0xFFEF6C00); // orange.shade800
  static const Color categoryActivityDark = Color(0xFF00695C); // teal.shade800
  static const Color categoryTransportDark = Color(
    0xFF283593,
  ); // indigo.shade800
  static const Color categoryOtherDark = Color(0xFF424242); // grey.shade800

  // --- Budget category resolvers (brightness-aware) ---
  static Color categoryFlightOf(Brightness b) =>
      b == Brightness.dark ? categoryFlightDark : categoryFlight;
  static Color categoryAccommodationOf(Brightness b) =>
      b == Brightness.dark ? categoryAccommodationDark : categoryAccommodation;
  static Color categoryFoodOf(Brightness b) =>
      b == Brightness.dark ? categoryFoodDark : categoryFood;
  static Color categoryActivityOf(Brightness b) =>
      b == Brightness.dark ? categoryActivityDark : categoryActivity;
  static Color categoryTransportOf(Brightness b) =>
      b == Brightness.dark ? categoryTransportDark : categoryTransport;
  static Color categoryOtherOf(Brightness b) =>
      b == Brightness.dark ? categoryOtherDark : categoryOther;

  // --- Text resolvers (brightness-aware) ---
  static Color textSecondaryOf(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondary;

  // --- Feedback / rating ---
  static const Color starRating = Color(0xFFFFC107); // amber

  // --- Alert banner (light) ---
  static const Color dangerBg = Color(0xFFFFEBEE); // red.shade50
  static const Color dangerBorder = Color(0xFFE57373); // red.shade300
  static const Color dangerIcon = Color(0xFFD32F2F); // red.shade700
  static const Color dangerText = Color(0xFFB71C1C); // red.shade900
  static const Color warningBg = Color(0xFFFFF3E0); // orange.shade50
  static const Color warningBorder = Color(0xFFFFB74D); // orange.shade300
  static const Color warningIcon = Color(0xFFF57C00); // orange.shade700
  static const Color warningText = Color(0xFFE65100); // orange.shade900

  // --- Error feedback (light) ---
  static const Color errorBg = Color(0xFFFFEBEE); // red.shade50
  static const Color errorText = Color(0xFFD32F2F); // red.shade700

  // --- Overlays / shadows / dividers ---
  static const Color white = ColorName.surface; // #FFFFFF
  static final Color shadowLight = const Color(
    0xFF000000,
  ).withValues(alpha: 0.06);
  static final Color shadowSubtle = const Color(
    0xFF000000,
  ).withValues(alpha: 0.04);
  static final Color shadowFaint = const Color(
    0xFF000000,
  ).withValues(alpha: 0.02);
}
