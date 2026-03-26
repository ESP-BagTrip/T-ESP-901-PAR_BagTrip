import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/models/duration_preset.dart';
import 'package:flutter/material.dart';

/// 2×2 grid of duration cards with icons.
class DurationChipSelector extends StatelessWidget {
  final DurationPreset? selected;
  final ValueChanged<DurationPreset> onSelected;

  const DurationChipSelector({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _buildItems(l10n);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.space8,
      crossAxisSpacing: AppSpacing.space8,
      childAspectRatio: 1.6,
      children: items.map((item) {
        final isSelected = selected == item.preset;

        return GestureDetector(
          onTap: () {
            AppHaptics.light();
            onSelected(item.preset);
          },
          child: AnimatedContainer(
            duration: AppAnimations.microInteraction,
            padding: AppSpacing.allEdgeInsetSpace12,
            decoration: BoxDecoration(
              color: isSelected ? ColorName.primaryLight : ColorName.surface,
              borderRadius: AppRadius.large16,
              border: Border.all(
                color: isSelected
                    ? ColorName.primary
                    : ColorName.primarySoftLight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isSelected
                      ? ColorName.primary
                      : ColorName.primaryTrueDark,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? ColorName.primary
                        : ColorName.primaryTrueDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 11,
                    color: isSelected ? ColorName.primary : ColorName.hint,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_DurationItem> _buildItems(AppLocalizations l10n) => [
    _DurationItem(
      preset: DurationPreset.weekend,
      icon: Icons.weekend_outlined,
      label: l10n.datesFlexibleWeekend,
      subtitle: l10n.datesFlexibleWeekendDays,
    ),
    _DurationItem(
      preset: DurationPreset.oneWeek,
      icon: Icons.calendar_view_week_outlined,
      label: l10n.datesFlexibleWeek,
      subtitle: l10n.datesFlexibleWeekDays,
    ),
    _DurationItem(
      preset: DurationPreset.twoWeeks,
      icon: Icons.calendar_month_outlined,
      label: l10n.datesFlexibleTwoWeeks,
      subtitle: l10n.datesFlexibleTwoWeeksDays,
    ),
    _DurationItem(
      preset: DurationPreset.threeWeeks,
      icon: Icons.date_range_outlined,
      label: l10n.datesFlexibleThreeWeeks,
      subtitle: l10n.datesFlexibleThreeWeeksDays,
    ),
  ];
}

class _DurationItem {
  final DurationPreset preset;
  final IconData icon;
  final String label;
  final String subtitle;

  const _DurationItem({
    required this.preset,
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}
