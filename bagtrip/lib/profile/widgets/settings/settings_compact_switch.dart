import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
import 'package:flutter/material.dart';

/// Scaled [Switch.adaptive] with profile-aligned track colors.
class SettingsCompactSwitch extends StatelessWidget {
  const SettingsCompactSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Transform.scale(
      scale: SettingsStyle.switchScale,
      alignment: Alignment.centerRight,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        activeTrackColor: SettingsStyle.switchActiveTrack(),
        activeThumbColor: SettingsStyle.switchThumb(),
        inactiveTrackColor: SettingsStyle.switchInactiveTrack(brightness),
        inactiveThumbColor: SettingsStyle.switchThumb(),
      ),
    );
  }
}
