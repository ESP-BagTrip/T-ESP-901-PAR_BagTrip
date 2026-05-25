import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/profile/widgets/settings/settings_compact_switch.dart';
import 'package:bagtrip/profile/widgets/settings/settings_icon_badge.dart';
import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
import 'package:flutter/material.dart';

/// Settings row with icon badge, title hierarchy, and unified switch.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final switchEnabled = enabled && onChanged != null;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          SettingsIconBadge(icon: icon, iconColor: iconColor),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: _TitleBlock(
              title: title,
              subtitle: subtitle,
              enabled: enabled,
              brightness: brightness,
            ),
          ),
          SettingsCompactSwitch(
            value: value,
            onChanged: switchEnabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.brightness,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: SettingsStyle.titleColor(brightness, enabled: enabled),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: SettingsStyle.subtitleColor(brightness, enabled: enabled),
          ),
        ),
      ],
    );
  }
}
