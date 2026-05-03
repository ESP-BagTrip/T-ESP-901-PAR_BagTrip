import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/models/ai_destination.dart';
import 'package:flutter/material.dart';

/// Hero-image destination card for the AI proposals carousel.
///
/// Pure presentation — no BLoC dependency. The [selectionProgress] (0.0–1.0)
/// drives the green overlay + checkmark animation externally.
class AiDestinationCard extends StatelessWidget {
  final AiDestination destination;
  final double selectionProgress;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const AiDestinationCard({
    super.key,
    required this.destination,
    this.selectionProgress = 0.0,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weatherLabel = destination.weatherSummary?.trim();
    final hasWeather = weatherLabel != null && weatherLabel.isNotEmpty;
    final activityLabels = destination.topActivities;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large16,
        color: ColorName.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image section with gradient overlay
          SizedBox(
            height: 192,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                if (destination.imageUrl != null)
                  OptimizedImage.activityImage(
                    destination.imageUrl!,
                    errorWidget: _imagePlaceholder(),
                  )
                else
                  _imagePlaceholder(),

                // Gradient overlay (bottom half)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.54),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // AI sparkle badge top-right
                Positioned(
                  top: AppSpacing.space8,
                  right: AppSpacing.space8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space8,
                      vertical: AppSpacing.space4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorName.secondary,
                      borderRadius: AppRadius.pill,
                      border: Border.all(color: ColorName.surface, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        Text(
                          l10n.aiBadgeLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // City + Country overlaid at bottom of image
                Positioned(
                  left: AppSpacing.space16,
                  bottom: AppSpacing.space12,
                  right: AppSpacing.space16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        destination.city,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        destination.country,
                        style: TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              AppSpacing.space12,
              AppSpacing.space16,
              AppSpacing.space12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match reason
                if (destination.matchReason != null) ...[
                  Text(
                    destination.matchReason!,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 14,

                      color: ColorName.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space16),
                ],

                // Weather + Budget chips
                if (hasWeather || destination.estimatedBudgetRange != null)
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space4,
                    children: [
                      if (hasWeather)
                        _InfoChip(
                          icon: Icons.wb_sunny_rounded,
                          label: weatherLabel,
                          backgroundColor: AppColors.chipWeatherBackground,
                          textColor: AppColors.chipWeatherForeground,
                          iconColor: AppColors.chipWeatherForeground,
                        ),
                      if (destination.estimatedBudgetRange != null)
                        _InfoChip(
                          icon: Icons.euro_rounded,
                          label:
                              '${destination.estimatedBudgetRange!.min.toInt()}–${destination.estimatedBudgetRange!.max.toInt()}€',
                        ),
                    ],
                  ),

                // Activity pills
                if (activityLabels.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space4,
                    children: activityLabels
                        .take(isExpanded ? activityLabels.length : 3)
                        .map(
                          (activity) => _InfoChip(
                            icon: Icons.place_rounded,
                            label: activity,
                            backgroundColor: AppColors.chipActivityBackground,
                            textColor: AppColors.chipActivityForeground,
                            iconColor: AppColors.chipActivityForeground,
                            textStyle: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: ColorName.primaryLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.landscape_rounded,
        size: 48,
        color: ColorName.hint,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final TextStyle? textStyle;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.backgroundColor = ColorName.primaryLight,
    this.textColor = ColorName.primary,
    this.iconColor = ColorName.primary,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.pill,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: AppSpacing.space4),
          Flexible(
            child: Text(
              label,
              style:
                  textStyle ??
                  TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
