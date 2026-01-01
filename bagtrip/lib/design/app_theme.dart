import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
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
      scaffoldBackgroundColor: Colors.white,
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
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorName.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace16,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace8,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          fontSize: 13,
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
}
