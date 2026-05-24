import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Immutable value object describing an inline hotel tile.
class ReviewInlineHotelData {
  const ReviewInlineHotelData({
    required this.name,
    required this.rating,
    required this.arrivalLabel,
    required this.staySummary,
    this.subtitle = '',
  });

  final String name;

  /// Number of stars (0 = unrated).
  final int rating;

  /// Localized arrival marker ("Check-in" / "Arrivée").
  final String arrivalLabel;

  /// Pre-formatted stay summary (e.g. "6 nights").
  final String staySummary;

  /// Optional neighborhood / descriptor rendered under the name.
  final String subtitle;
}

/// Refined hotel tile — small uppercase arrival eyebrow, serif name, stars
/// aligned to the baseline, soft ivory paper.
class ReviewInlineHotel extends StatelessWidget {
  const ReviewInlineHotel({super.key, required this.data});

  final ReviewInlineHotelData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAF7),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.reviewBorderLight, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hotel_outlined,
                  size: 12,
                  color: AppColors.reviewInk.withValues(alpha: 0.45),
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  data.arrivalLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: AppColors.reviewInk.withValues(alpha: 0.55),
                  ),
                ),
                const Spacer(),
                if (data.rating > 0) _StarsRow(count: data.rating),
              ],
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              data.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 22,
                height: 1.15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
                color: AppColors.reviewInk,
              ),
            ),
            if (_composedSubtitle().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _composedSubtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.reviewSubtle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _composedSubtitle() {
    final parts = <String>[
      if (data.staySummary.isNotEmpty) data.staySummary,
      if (data.subtitle.isNotEmpty) data.subtitle,
    ];
    return parts.join(' · ');
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count.clamp(0, 5),
        (_) => Icon(
          Icons.star_rounded,
          size: 12,
          color: AppColors.reviewInk.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
