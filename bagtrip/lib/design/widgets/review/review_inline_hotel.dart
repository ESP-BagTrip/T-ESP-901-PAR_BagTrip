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

  /// Localized label for the arrival marker ("Check-in" / "Arrivée").
  final String arrivalLabel;

  /// Pre-formatted stay summary (e.g. "6 nights").
  final String staySummary;

  /// Optional neighborhood / descriptor rendered under the hotel name.
  final String subtitle;
}

/// Rich hotel tile with gradient header strip, name in serif and stars row.
class ReviewInlineHotel extends StatelessWidget {
  const ReviewInlineHotel({super.key, required this.data});

  final ReviewInlineHotelData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F3),
        borderRadius: AppRadius.large16,
        border: Border.all(color: AppColors.reviewBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD4A574), Color(0xFF8B6F47)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.cornerRaidus16),
                topRight: Radius.circular(AppRadius.cornerRaidus16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.18),
                    borderRadius: AppRadius.large13,
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    size: 20,
                    color: Color(0xFF8B6F47),
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD4A574,
                              ).withValues(alpha: 0.18),
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              data.arrivalLabel.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Color(0xFF8B6F47),
                              ),
                            ),
                          ),
                          if (data.rating > 0) ...[
                            const Spacer(),
                            _StarsRow(count: data.rating),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        data.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSerifDisplay,
                          fontSize: 19,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.reviewInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _composedSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.reviewSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        (_) => const Icon(
          Icons.star_rounded,
          size: 14,
          color: AppColors.starRating,
        ),
      ),
    );
  }
}
