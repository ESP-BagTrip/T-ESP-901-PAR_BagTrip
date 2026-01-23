import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

enum SocialProvider { google, apple }

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLoading = false,
  });

  String get _label {
    switch (provider) {
      case SocialProvider.google:
        return 'Continuer avec Google';
      case SocialProvider.apple:
        return 'Continuer avec Apple';
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

  Color get _backgroundColor {
    switch (provider) {
      case SocialProvider.google:
        return Colors.white;
      case SocialProvider.apple:
        return Colors.black;
    }
  }

  Color get _textColor {
    switch (provider) {
      case SocialProvider.google:
        return ColorName.primaryTrueDark;
      case SocialProvider.apple:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          side: BorderSide(
            color:
                provider == SocialProvider.google
                    ? ColorName.primarySoftLight
                    : Colors.black,
            width: 1.5,
          ),
          minimumSize: const Size.fromHeight(AppSize.height42),
          padding: AppSpacing.allEdgeInsetSpace16,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon, size: 20),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      _label,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
