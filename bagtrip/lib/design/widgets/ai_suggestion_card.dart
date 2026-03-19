import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Enriched AI suggestion card with image, match reason, and badges.
///
/// Pure design-system component — no BLoC or model dependency.
class AiSuggestionCard extends StatelessWidget {
  final String destination;
  final String country;
  final String? imageUrl;
  final String? matchReason;
  final int? durationDays;
  final int? priceEur;
  final List<String>? badges;
  final bool isSelected;
  final VoidCallback onTap;

  const AiSuggestionCard({
    super.key,
    required this.destination,
    required this.country,
    this.imageUrl,
    this.matchReason,
    this.durationDays,
    this.priceEur,
    this.badges,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.medium();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppAnimations.microInteraction,
        curve: AppAnimations.standardCurve,
        decoration: BoxDecoration(
          borderRadius: AppRadius.large16,
          color: ColorName.surface,
          border: Border.all(
            color: isSelected ? ColorName.primary : ColorName.primarySoftLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ColorName.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 4),
              blurRadius: isSelected ? 12 : 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.cornerRaidus16),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),

            // Content section
            Padding(
              padding: AppSpacing.allEdgeInsetSpace16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination + country
                  Text(
                    destination,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ColorName.primaryTrueDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    country,
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      color: ColorName.hint,
                    ),
                  ),

                  // Match reason
                  if (matchReason != null) ...[
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      matchReason!,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: ColorName.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Chips: duration + price
                  if (durationDays != null || priceEur != null) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Row(
                      children: [
                        if (durationDays != null && durationDays! > 0) ...[
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: '${durationDays}d',
                          ),
                          const SizedBox(width: AppSpacing.space8),
                        ],
                        if (priceEur != null && priceEur! > 0)
                          _InfoChip(
                            icon: Icons.euro_rounded,
                            label: '$priceEur€',
                          ),
                      ],
                    ),
                  ],

                  // Badges
                  if (badges != null && badges!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Wrap(
                      spacing: AppSpacing.space8,
                      runSpacing: AppSpacing.space4,
                      children: badges!
                          .map(
                            (badge) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space8,
                                vertical: AppSpacing.space4,
                              ),
                              decoration: const BoxDecoration(
                                color: ColorName.primaryLight,
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                badge,
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
          ],
        ),
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
