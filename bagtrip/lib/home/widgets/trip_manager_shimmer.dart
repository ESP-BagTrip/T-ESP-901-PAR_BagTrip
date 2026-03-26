import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TripManagerShimmer extends StatelessWidget {
  const TripManagerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ColorName.shimmerBase,
      highlightColor: ColorName.shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
        child: Column(
          children: [
            // Hero skeleton
            Container(
              height: 100,
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.large16,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            // 2 compact card skeletons
            for (int i = 0; i < 2; i++) ...[
              Container(
                height: 72,
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.large16,
                ),
              ),
              if (i < 1) const SizedBox(height: AppSpacing.space12),
            ],
          ],
        ),
      ),
    );
  }
}
