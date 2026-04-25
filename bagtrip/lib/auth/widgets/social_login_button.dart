import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

enum SocialProvider { google, apple }

class SocialLoginButton extends StatelessWidget {
  static const double _height = 47;

  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool useDarkStyle;
  final String? label;

  const SocialLoginButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLoading = false,
    this.useDarkStyle = false,
    this.label,
  });

  String get _defaultLabel {
    switch (provider) {
      case SocialProvider.google:
        return 'Google';
      case SocialProvider.apple:
        return 'Apple';
    }
  }

  IconData get _icon {
    switch (provider) {
      case SocialProvider.google:
        return Icons.g_mobiledata;
      case SocialProvider.apple:
        return Icons.apple;
    }
  }

  double get _iconSize {
    switch (provider) {
      case SocialProvider.google:
        return 26;
      case SocialProvider.apple:
        return 20;
    }
  }

  Color get _backgroundColor {
    if (useDarkStyle) return AppColors.primaryTrueDark;
    switch (provider) {
      case SocialProvider.google:
        return AppColors.surface;
      case SocialProvider.apple:
        return AppColors.primaryTrueDark;
    }
  }

  Color get _textColor {
    if (useDarkStyle) return AppColors.surface;
    switch (provider) {
      case SocialProvider.google:
        return ColorName.primaryTrueDark;
      case SocialProvider.apple:
        return AppColors.surface;
    }
  }

  BorderSide get _side {
    if (useDarkStyle) {
      return BorderSide(color: AppColors.surface.withValues(alpha: 0.2));
    }
    return BorderSide(
      color: provider == SocialProvider.google
          ? ColorName.primarySoftLight
          : AppColors.primaryTrueDark,
      width: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabel = label ?? _defaultLabel;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          side: _side,
          minimumSize: const Size.fromHeight(_height),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icon, size: _iconSize, color: _textColor),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
