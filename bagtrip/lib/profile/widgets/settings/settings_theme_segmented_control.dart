import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/profile/widgets/settings/settings_style.dart';
import 'package:flutter/material.dart';

/// Three-way theme picker: gray track, sliding indicator, icon + label segments.
class SettingsThemeSegmentedControl extends StatelessWidget {
  const SettingsThemeSegmentedControl({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
    required this.lightLabel,
    required this.darkLabel,
    required this.systemLabel,
  });

  final String selectedTheme;
  final ValueChanged<String> onThemeChanged;
  final String lightLabel;
  final String darkLabel;
  final String systemLabel;

  static const _themes = ['light', 'dark', 'system'];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedIndex = _themes.indexOf(selectedTheme).clamp(0, 2);
    final trackColor = SettingsStyle.themeTrackBackground(brightness);
    final indicatorColor = SettingsStyle.themeIndicatorBackground(brightness);

    return Container(
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: AppRadius.medium12,
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.space4;
          final segmentWidth = (constraints.maxWidth - 2 * gap) / 3;
          final indicatorLeft = selectedIndex * (segmentWidth + gap);

          return SizedBox(
            height: 40,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AppAnimationDurations.quick,
                  curve: Curves.easeOutCubic,
                  left: indicatorLeft,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      borderRadius: AppRadius.medium12,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Segment(
                        brightness: brightness,
                        icon: Icons.light_mode_outlined,
                        label: lightLabel,
                        selected: selectedTheme == 'light',
                        onTap: () => onThemeChanged('light'),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _Segment(
                        brightness: brightness,
                        icon: Icons.dark_mode_outlined,
                        label: darkLabel,
                        selected: selectedTheme == 'dark',
                        onTap: () => onThemeChanged('dark'),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _Segment(
                        brightness: brightness,
                        icon: Icons.desktop_windows_outlined,
                        label: systemLabel,
                        selected: selectedTheme == 'system',
                        onTap: () => onThemeChanged('system'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.brightness,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Brightness brightness;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? SettingsStyle.themeSegmentSelectedForeground(brightness)
        : SettingsStyle.themeSegmentUnselectedForeground(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium12,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: AppSpacing.space4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
