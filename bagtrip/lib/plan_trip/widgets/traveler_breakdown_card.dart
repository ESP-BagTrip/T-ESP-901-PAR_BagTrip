import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/widgets/compact_traveler_stepper.dart';
import 'package:flutter/material.dart';

/// Single card with three rows (adults / children / babies), iOS settings style.
class TravelerBreakdownCard extends StatelessWidget {
  const TravelerBreakdownCard({
    super.key,
    required this.nbAdults,
    required this.nbChildren,
    required this.nbBabies,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    required this.onBabiesChanged,
    this.maxPerCategory = 10,
  });

  final int nbAdults;
  final int nbChildren;
  final int nbBabies;
  final ValueChanged<int> onAdultsChanged;
  final ValueChanged<int> onChildrenChanged;
  final ValueChanged<int> onBabiesChanged;
  final int maxPerCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final dividerColor = AppColors.surfaceGroupBorderOf(brightness);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceGroupOf(brightness),
        borderRadius: AppRadius.large24,
        border: Border.all(color: AppColors.surfaceGroupBorderOf(brightness)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Row(
            title: l10n.travelerTypeAdults,
            subtitle: l10n.travelerAgeAdultsSubtitle,
            value: nbAdults,
            min: 1,
            max: maxPerCategory,
            onChanged: onAdultsChanged,
            brightness: brightness,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _Row(
            title: l10n.travelerTypeChildren,
            subtitle: l10n.travelerAgeChildrenSubtitle,
            value: nbChildren,
            min: 0,
            max: maxPerCategory,
            onChanged: onChildrenChanged,
            brightness: brightness,
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _Row(
            title: l10n.travelerTypeBabies,
            subtitle: l10n.travelerAgeBabiesSubtitle,
            value: nbBabies,
            min: 0,
            max: maxPerCategory,
            onChanged: onBabiesChanged,
            brightness: brightness,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.brightness,
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final titleColor = AppColors.profileMenuTitleOf(brightness);
    final mutedColor = AppColors.textSecondaryOf(brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          CompactTravelerStepper(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
