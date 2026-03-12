import 'package:flutter/material.dart';

/// Premium color palette for the personalization / onboarding flow.
/// Soft gradients (blue → violet), neutral backgrounds, glass surfaces.
class PersonalizationColors {
  PersonalizationColors._();

  // --- Background gradients (calm, light) ---
  static const Color gradientStart = Color(0xFFF0F4FA);
  static const Color gradientMid = Color(0xFFF5F3F8);
  static const Color gradientEnd = Color(0xFFFAF8FC);

  static const List<Color> backgroundGradient = [
    gradientStart,
    gradientMid,
    gradientEnd,
  ];

  // --- Accent gradient (blue → violet) ---
  static const Color accentBlue = Color(0xFF5B7CFD);
  static const Color accentViolet = Color(0xFF8B7BFF);

  static const List<Color> accentGradient = [accentBlue, accentViolet];

  // --- Glass / frosted surfaces ---
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceGlassBorder = Color(0x26FFFFFF);
  static const Color glassOverlay = Color(0x0DFFFFFF);

  // --- Neutral text ---
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6B6B70);
  static const Color textTertiary = Color(0xFF8E8E93);

  // --- Card states ---
  static const Color cardUnselected = Color(0x14FFFFFF);
  static const Color cardSelectedTint = Color(0x1A5B7CFD);
  static const Color cardBorderUnselected = Color(0x1A000000);
  static const Color cardBorderSelected = Color(0xFF5B7CFD);

  // --- Chip ---
  static const Color chipUnselected = Color(0x14FFFFFF);
  static const Color chipSelected = Color(0x265B7CFD);
}
