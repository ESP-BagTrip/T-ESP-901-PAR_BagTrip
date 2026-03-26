import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class FlightPreviewCard extends StatelessWidget {
  const FlightPreviewCard({
    super.key,
    required this.route,
    required this.details,
    required this.price,
    required this.source,
    required this.animationIndex,
  });

  final String route;
  final String details;
  final double price;
  final String source;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVerified = source.toLowerCase() == 'verified';

    return StaggeredFadeIn(
      index: animationIndex,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large16,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left gradient bar
            Container(
              width: 4,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: PersonalizationColors.accentGradient,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            // Icon box
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.medium8,
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: PersonalizationColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      details,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: PersonalizationColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        Text(
                          l10n.reviewPriceEur(price.toStringAsFixed(0)),
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        _SourceBadge(
                          label: isVerified
                              ? l10n.reviewSourceVerified
                              : l10n.reviewSourceEstimated,
                          isVerified: isVerified,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label, required this.isVerified});

  final String label;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.warningLight,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isVerified ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}
