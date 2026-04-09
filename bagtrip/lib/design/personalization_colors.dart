import 'package:flutter/material.dart';

/// Premium color palette for the personalization / onboarding flow.
/// Soft gradients (blue → violet), neutral backgrounds, glass surfaces.
///
/// Static constants are light-mode values (backward-compatible).
/// Use the `of(Brightness)` methods for dark-mode-aware colors.
class PersonalizationColors {
  PersonalizationColors._();

  // ──────────────────── Background gradients ────────────────────
  // Light (existing API, unchanged)
  static const Color gradientStart = Color(0xFFF0F4FA);
  static const Color gradientMid = Color(0xFFF5F3F8);
  static const Color gradientEnd = Color(0xFFFAF8FC);

  static const List<Color> backgroundGradient = [
    gradientStart,
    gradientMid,
    gradientEnd,
  ];

  // Dark variants
  static const Color _gradientStartDark = Color(0xFF0E1A2B);
  static const Color _gradientMidDark = Color(0xFF151D2E);
  static const Color _gradientEndDark = Color(0xFF1A1F30);

  // ──────────────────── Accent gradient (shared) ────────────────────
  static const Color accentBlue = Color(0xFF5B7CFD);
  static const Color accentViolet = Color(0xFF8B7BFF);
  static const List<Color> accentGradient = [accentBlue, accentViolet];

  // ──────────────────── Glass / frosted surfaces (shared) ────────────
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceGlassBorder = Color(0x26FFFFFF);
  static const Color glassOverlay = Color(0x0DFFFFFF);

  // ──────────────────── Text ────────────────────
  // Light (existing API, unchanged)
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B6B70);
  static const Color textTertiary = Color(0xFF8E8E93);

  // Dark variants
  static const Color _textPrimaryDark = Color(0xFFF5F5F7);
  static const Color _textSecondaryDark = Color(0xFFB0B0B5);
  static const Color _textTertiaryDark = Color(0xFF8E8E93);

  // ──────────────────── Card states ────────────────────
  // Light (existing API, unchanged)
  static const Color cardUnselected = Color(0x14FFFFFF);
  static const Color cardSelectedTint = Color(0x1A5B7CFD);
  static const Color cardBorderUnselected = Color(0x1A000000);
  static const Color cardBorderSelected = Color(0xFF5B7CFD);

  // Dark variants
  static const Color _cardUnselectedDark = Color(0x14FFFFFF);
  static const Color _cardSelectedTintDark = Color(0x335B7CFD);
  static const Color _cardBorderUnselectedDark = Color(0x26FFFFFF);

  // ──────────────────── Chip ────────────────────
  // Light (existing API, unchanged)
  static const Color chipUnselected = Color(0x14FFFFFF);
  static const Color chipSelected = Color(0x265B7CFD);

  // Dark variants
  static const Color _chipUnselectedDark = Color(0x1AFFFFFF);
  static const Color _chipSelectedDark = Color(0x335B7CFD);

  // ══════════════════════════════════════════════════════════════
  // Brightness-aware resolvers
  // ══════════════════════════════════════════════════════════════

  static Color gradientStartOf(Brightness b) =>
      b == Brightness.dark ? _gradientStartDark : gradientStart;

  static Color gradientMidOf(Brightness b) =>
      b == Brightness.dark ? _gradientMidDark : gradientMid;

  static Color gradientEndOf(Brightness b) =>
      b == Brightness.dark ? _gradientEndDark : gradientEnd;

  static List<Color> backgroundGradientOf(Brightness b) => [
    gradientStartOf(b),
    gradientMidOf(b),
    gradientEndOf(b),
  ];

  static Color textPrimaryOf(Brightness b) =>
      b == Brightness.dark ? _textPrimaryDark : textPrimary;

  static Color textSecondaryOf(Brightness b) =>
      b == Brightness.dark ? _textSecondaryDark : textSecondary;

  static Color textTertiaryOf(Brightness b) =>
      b == Brightness.dark ? _textTertiaryDark : textTertiary;

  static Color cardUnselectedOf(Brightness b) =>
      b == Brightness.dark ? _cardUnselectedDark : cardUnselected;

  static Color cardSelectedTintOf(Brightness b) =>
      b == Brightness.dark ? _cardSelectedTintDark : cardSelectedTint;

  static Color cardBorderUnselectedOf(Brightness b) =>
      b == Brightness.dark ? _cardBorderUnselectedDark : cardBorderUnselected;

  static Color chipUnselectedOf(Brightness b) =>
      b == Brightness.dark ? _chipUnselectedDark : chipUnselected;

  static Color chipSelectedOf(Brightness b) =>
      b == Brightness.dark ? _chipSelectedDark : chipSelected;
}
