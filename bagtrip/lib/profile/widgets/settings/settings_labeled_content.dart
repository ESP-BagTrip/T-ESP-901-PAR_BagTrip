import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
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
  });

  final String label;
  final String title;
  final String? subtitle;
  final bool enabled;
  final bool boldTitle;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final titleColor = SettingsStyle.titleColor(brightness, enabled: enabled);
    final secondaryColor = SettingsStyle.subtitleColor(
      brightness,
      enabled: enabled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          title,
          style: TextStyle(
            fontSize: boldTitle ? 15 : 13,
            fontWeight: boldTitle ? FontWeight.w600 : FontWeight.w400,
            color: boldTitle ? titleColor : secondaryColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
        ],
      ],
    );
  }
}
