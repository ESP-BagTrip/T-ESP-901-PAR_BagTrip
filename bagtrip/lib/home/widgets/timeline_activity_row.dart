import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

class TimelineActivityRow extends StatelessWidget {
  final Activity activity;
  final bool isNext;
  final bool isLast;

  const TimelineActivityRow({
    super.key,
    required this.activity,
    this.isNext = false,
    this.isLast = false,
  });

  IconData _categoryIcon(ActivityCategory category) {
    return switch (category) {
      ActivityCategory.culture => Icons.museum_outlined,
      ActivityCategory.nature => Icons.park_outlined,
      ActivityCategory.food => Icons.restaurant_outlined,
      ActivityCategory.sport => Icons.fitness_center_outlined,
      ActivityCategory.shopping => Icons.shopping_bag_outlined,
      ActivityCategory.nightlife => Icons.nightlife_outlined,
      ActivityCategory.relaxation => Icons.spa_outlined,
      ActivityCategory.other => Icons.event_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Top connector
                Expanded(
                  child: Container(
                    width: 2,
                    color: ColorName.primary.withValues(alpha: 0.2),
                  ),
                ),
                // Dot
                Container(
                  width: isNext ? 12 : 8,
                  height: isNext ? 12 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNext ? ColorName.primary : Colors.transparent,
                    border: isNext
                        ? null
                        : Border.all(
                            color: ColorName.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                  ),
                ),
                // Bottom connector
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: ColorName.primary.withValues(alpha: 0.2),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space12,
              ),
              decoration: BoxDecoration(
                color: isNext
                    ? ColorName.primary.withValues(alpha: 0.05)
                    : theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: AppRadius.medium8,
                border: Border.all(
                  color: isNext
                      ? ColorName.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  // Time or all-day label
                  SizedBox(
                    width: 48,
                    child: Text(
                      activity.startTime ?? l10n.activeTripsAllDay,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isNext
                            ? ColorName.primary
                            : ColorName.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  // Title
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  // Category icon
                  Icon(
                    _categoryIcon(activity.category),
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
