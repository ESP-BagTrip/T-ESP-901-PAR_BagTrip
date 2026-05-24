import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorName.primary,
        primary: ColorName.primary,
        secondary: ColorName.secondary,
        surface: ColorName.primaryLight,
        error: ColorName.error,
      ),
      scaffoldBackgroundColor: PersonalizationColors.gradientStart,
      fontFamily: FontFamily.b612,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ColorName.primary,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ColorName.primaryTrueDark,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: ColorName.primaryTrueDark,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorName.secondary,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace16,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace8,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: base.textTheme.bodySmall?.copyWith(
          fontFamily: FontFamily.b612,
          color: ColorName.primary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: ColorName.primarySoftLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large16),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorName.secondary,
        primary: ColorName.secondary,
        secondary: ColorName.secondary,
        surface: ColorName.primaryDark,
        error: ColorName.error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: ColorName.primaryTrueDark,
      fontFamily: FontFamily.b612,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ColorName.secondary,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.surface,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorName.secondary,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace16,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace8,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: base.textTheme.bodySmall?.copyWith(
          fontFamily: FontFamily.b612,
          color: ColorName.surface.withValues(alpha: 0.7),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: ColorName.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large16),
      ),
    );
  }

  /// Cupertino light theme — reuses existing brand colors with iOS styling.
  static CupertinoThemeData cupertinoLight() {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: ColorName.secondary,
      primaryContrastingColor: AppColors.surface,
      scaffoldBackgroundColor: PersonalizationColors.gradientStart,
      barBackgroundColor: PersonalizationColors.gradientStart.withValues(
        alpha: 0.94,
      ),
      textTheme: const CupertinoTextThemeData(
        primaryColor: ColorName.secondary,
        textStyle: TextStyle(
          fontFamily: FontFamily.b612,
          color: ColorName.primaryTrueDark,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: FontFamily.b612,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: ColorName.primaryTrueDark,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: FontFamily.b612,
          fontWeight: FontWeight.w700,
          fontSize: 34,
          color: ColorName.primaryTrueDark,
        ),
      ),
    );
  }

  /// Cupertino dark theme.
  static CupertinoThemeData cupertinoDark() {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: ColorName.secondary,
      primaryContrastingColor: AppColors.surface,
      scaffoldBackgroundColor: ColorName.primaryTrueDark,
      barBackgroundColor: ColorName.primaryTrueDark.withValues(alpha: 0.94),
      textTheme: const CupertinoTextThemeData(
        primaryColor: ColorName.secondary,
        textStyle: TextStyle(
          fontFamily: FontFamily.b612,
          color: AppColors.surface,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: FontFamily.b612,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: AppColors.surface,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: FontFamily.b612,
          fontWeight: FontWeight.w700,
          fontSize: 34,
          color: AppColors.surface,
        ),
      ),
    );
  }
}
