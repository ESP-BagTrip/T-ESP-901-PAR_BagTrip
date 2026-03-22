import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/personalization_colors.dart';
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

  const AiDestinationCard({
    super.key,
    required this.destination,
    this.selectionProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
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
                      color: PersonalizationColors.accentBlue.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        Text(
                          l10n.aiBadgeLabel,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 11,
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
                          fontFamily: FontFamily.b612,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        destination.country,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection overlay
                if (selectionProgress > 0)
                  Positioned.fill(
                    child: Container(
                      color: ColorName.success.withValues(
                        alpha: selectionProgress * 0.3,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 48 * selectionProgress,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: Padding(
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
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ColorName.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                  ],

                  // Weather + Budget chips
                  Wrap(
                    spacing: AppSpacing.space8,
                    runSpacing: AppSpacing.space4,
                    children: [
                      if (destination.weatherSummary != null)
                        _InfoChip(
                          icon: Icons.wb_sunny_rounded,
                          label: destination.weatherSummary!,
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
                  if (destination.topActivities.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space8),
                    Wrap(
                      spacing: AppSpacing.space8,
                      runSpacing: AppSpacing.space4,
                      children: destination.topActivities
                          .take(3)
                          .map(
                            (activity) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space8,
                                vertical: AppSpacing.space4,
                              ),
                              decoration: const BoxDecoration(
                                color: ColorName.primaryLight,
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                activity,
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ColorName.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: const BoxDecoration(
        color: ColorName.primaryLight,
        borderRadius: AppRadius.medium8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ColorName.primary),
          const SizedBox(width: AppSpacing.space4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ColorName.primary,
            ),
          ),
        ],
      ),
    );
  }
}
