import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/plan_trip/models/trip_plan.dart';
import 'package:flutter/material.dart';

/// Inline section listing the AI's undated recommendations
/// ("Restos à essayer", "Transports utiles").
///
/// SMP-324 — those recommendations replace the previous orphan
/// ``Repas estimés`` / ``Transport estimé`` budget rows. Each entry
/// here is backed by a real ``Activity`` row (no date) so the trip
/// detail tab can edit / delete it later. The widget is read-only.
class ReviewRecommendationSection extends StatelessWidget {
  const ReviewRecommendationSection({
    super.key,
    required this.title,
    required this.icon,
    required this.recommendations,
  });

  final String title;
  final IconData icon;
  final List<TripRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space24,
        AppSpacing.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ColorName.secondary),
              const SizedBox(width: AppSpacing.space8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorName.secondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space12),
          ...recommendations.map(
            (reco) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space8),
              child: _RecommendationCard(reco: reco),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.reco});

  final TripRecommendation reco;

  @override
  Widget build(BuildContext context) {
    final priceLabel = reco.estimatedCost > 0
        ? reco.estimatedCost.formatPrice()
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reco.title,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: ColorName.onSurface,
                  ),
                ),
                if (reco.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    reco.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      color: ColorName.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                if (reco.location.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    reco.location,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorName.hint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (priceLabel != null) ...[
            const SizedBox(width: AppSpacing.space12),
            Text(
              priceLabel,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: ColorName.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
