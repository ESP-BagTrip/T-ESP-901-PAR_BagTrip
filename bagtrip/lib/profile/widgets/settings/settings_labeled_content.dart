import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/profile/widgets/profile_detail_style.dart';
import 'package:flutter/material.dart';

/// Label (uppercase) + title + optional subtitle for settings rows.
class SettingsLabeledContent extends StatelessWidget {
  const SettingsLabeledContent({
    super.key,
    required this.label,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.boldTitle = true,
    this.titleColor,
    this.showLabel = true,
    this.cardSerifTypography = false,
    this.personalInfoTypography = false,
  });

  final String label;
  final String title;
  final String? subtitle;
  final bool enabled;
  final bool boldTitle;
  final Color? titleColor;
  final bool showLabel;
  final bool cardSerifTypography;
  final bool personalInfoTypography;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resolvedTitleColor =
        titleColor ??
        ProfileDetailStyle.titleColor(brightness, enabled: enabled);
    final secondaryColor = ProfileDetailStyle.subtitleColor(
      brightness,
      enabled: enabled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: personalInfoTypography
                ? ProfileDetailStyle.fieldLabelStyle(
                    brightness,
                    enabled: enabled,
                  )
                : TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                    letterSpacing: 0.5,
                  ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],
        Text(
          title,
          style: _titleTextStyle(
            brightness: brightness,
            boldTitle: boldTitle,
            resolvedTitleColor: resolvedTitleColor,
            secondaryColor: secondaryColor,
            enabled: enabled,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            subtitle!,
            style: _subtitleTextStyle(
              brightness: brightness,
              secondaryColor: secondaryColor,
              enabled: enabled,
            ),
          ),
        ],
      ],
    );
  }

  TextStyle _titleTextStyle({
    required Brightness brightness,
    required bool boldTitle,
    required Color resolvedTitleColor,
    required Color secondaryColor,
    required bool enabled,
  }) {
    if (personalInfoTypography || cardSerifTypography) {
      return ProfileDetailStyle.cardTitleStyle(
        brightness,
        color: boldTitle ? resolvedTitleColor : secondaryColor,
        enabled: enabled,
        fontWeight: boldTitle ? FontWeight.w600 : FontWeight.w400,
      );
    }
    return TextStyle(
      fontSize: boldTitle ? 15 : 13,
      fontWeight: boldTitle ? FontWeight.w600 : FontWeight.w400,
      color: boldTitle ? resolvedTitleColor : secondaryColor,
    );
  }

  TextStyle _subtitleTextStyle({
    required Brightness brightness,
    required Color secondaryColor,
    required bool enabled,
  }) {
    if (personalInfoTypography || cardSerifTypography) {
      return ProfileDetailStyle.cardSubtitleStyle(brightness, enabled: enabled);
    }
    return TextStyle(fontSize: 13, color: secondaryColor);
  }
}
