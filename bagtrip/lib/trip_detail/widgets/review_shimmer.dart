import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loading state for the new [TripDetailView].
///
/// Matches the target silhouette (dark hero + pill chips row + content
/// placeholder), so the switch from shimmer to real content does not flash
/// the layout.
class ReviewShimmer extends StatelessWidget {
  const ReviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ColoredBox(
      color: ColorName.surfaceVariant,
      child: Column(
        children: [
          // Dark hero placeholder
          Container(
            color: ColorName.primaryDark,
            padding: EdgeInsets.only(
              top: topPadding + AppSpacing.space12,
              left: AppSpacing.space16,
              right: AppSpacing.space16,
              bottom: AppSpacing.space16,
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.white.withValues(alpha: 0.12),
              highlightColor: Colors.white.withValues(alpha: 0.22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _shimmerBox(width: 40, height: 40, radius: 20),
                      const Spacer(),
                      _shimmerBox(width: 40, height: 40, radius: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _shimmerBox(height: 30)),
                      const SizedBox(width: AppSpacing.space12),
                      _shimmerBox(width: 60, height: 50, radius: 25),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  _shimmerBox(width: 160, height: 16),
                ],
              ),
            ),
          ),
          // Chips bar placeholder
          ColoredBox(
            color: ColorName.primaryDark,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space8,
                AppSpacing.space16,
                AppSpacing.space12,
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.1),
                highlightColor: Colors.white.withValues(alpha: 0.22),
                child: _shimmerBox(
                  height: 40,
                  radius: AppRadius.cornerRadius20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          // Content placeholders
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                itemCount: 4,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.space12),
                itemBuilder: (_, _) =>
                    _shimmerBox(height: 96, radius: AppRadius.cornerRaidus16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({double? width, double height = 12, double radius = 8}) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
