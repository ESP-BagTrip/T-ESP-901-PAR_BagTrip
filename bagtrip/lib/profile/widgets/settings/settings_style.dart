import 'package:bagtrip/design/app_colors.dart';
import 'package:flutter/material.dart';

/// Brightness-aware colors and sizing for the settings page (aligned with profile).
abstract final class SettingsStyle {
  SettingsStyle._();

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

  /// Icon badge tints (same semantics as [ProfileMenuRow] on profile).
  static Color iconAccentSecondary() => AppColors.secondary;

  static Color iconAccentWarning() => AppColors.warning;

  static Color iconAccentMuted() => AppColors.hint;
}
