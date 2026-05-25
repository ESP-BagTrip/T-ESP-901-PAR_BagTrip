import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Brightness-aware colors and sizing for profile sub-pages (settings, info, subscription).
abstract final class ProfileDetailStyle {
  ProfileDetailStyle._();

  /// Slightly smaller than the platform default switch.
  static const double switchScale = 0.82;

  static Color titleColor(Brightness brightness, {required bool enabled}) {
    final base = AppColors.profileMenuTitleOf(brightness);
    return enabled ? base : base.withValues(alpha: 0.4);
  }

  static Color subtitleColor(Brightness brightness, {required bool enabled}) {
    final base = AppColors.textSecondaryOf(brightness);
    return enabled ? base : base.withValues(alpha: 0.4);
  }

  static Color chevronColor(Brightness brightness) => AppColors.hint;

  static Color themeTrackBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppColors.inputBackgroundDark
      : AppColors.primaryLight;

  static Color themeIndicatorBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppColors.surface
      : AppColors.primaryTrueDark;

  static Color themeSegmentSelectedForeground(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppColors.primaryTrueDark
      : AppColors.surface;

  static Color themeSegmentUnselectedForeground(Brightness brightness) =>
      AppColors.profileMenuMutedOf(brightness);

  static Color switchInactiveTrack(Brightness brightness) =>
      brightness == Brightness.dark
      ? AppColors.surface.withValues(alpha: 0.2)
      : AppColors.border;

  static Color switchActiveTrack() => AppColors.secondary;

  static Color switchThumb() => AppColors.surface;

  static Color iconAccentSecondary() => AppColors.secondary;

  static Color iconAccentPrimary() => AppColors.primary;

  static Color iconAccentWarning() => AppColors.warning;

  static Color iconAccentMuted() => AppColors.hint;

  static Color iconAccentDestructive() => AppColors.error;

  static TextStyle modifyButtonStyle() => const TextStyle(
    fontSize: 14,
    color: AppColors.secondary,
    fontWeight: FontWeight.w600,
  );

  /// Card body text (e.g. Mon abonnement) — matches profile menu rows.
  static TextStyle cardTitleStyle(
    Brightness brightness, {
    Color? color,
    bool enabled = true,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: FontFamily.dMSerifDisplay,
      fontSize: 14,
      fontWeight: fontWeight,
      color: color ?? titleColor(brightness, enabled: enabled),
    );
  }

  static TextStyle cardSubtitleStyle(
    Brightness brightness, {
    bool enabled = true,
  }) {
    return TextStyle(
      fontFamily: FontFamily.dMSerifDisplay,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: subtitleColor(brightness, enabled: enabled),
    );
  }

  /// Uppercase field label (e.g. informations personnelles rows).
  static TextStyle fieldLabelStyle(
    Brightness brightness, {
    bool enabled = true,
  }) {
    return TextStyle(
      fontFamily: FontFamily.dMSans,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: subtitleColor(brightness, enabled: enabled),
    );
  }
}
