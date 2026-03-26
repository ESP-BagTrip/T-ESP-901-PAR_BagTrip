import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TripDetailShimmer extends StatelessWidget {
  const TripDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ColorName.shimmerBase,
      highlightColor: ColorName.shimmerHighlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Hero placeholder
            Container(
              height: 280,
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            // Stats row skeleton
            Padding(
              padding: AppSpacing.horizontalSpace24,
              child: Container(
                height: 72,
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.large20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            // Completion bar skeleton
            Padding(
              padding: AppSpacing.horizontalSpace24,
              child: Container(
                height: 32,
                decoration: const BoxDecoration(
                  color: ColorName.primaryLight,
                  borderRadius: AppRadius.pill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            // Quick actions row skeleton
            Padding(
              padding: AppSpacing.horizontalSpace24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (_) => Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: ColorName.primaryLight,
                      borderRadius: AppRadius.large16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            // 4 section card skeletons
            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: AppSpacing.horizontalSpace24,
                child: Container(
                  height: 88,
                  decoration: const BoxDecoration(
                    color: ColorName.primaryLight,
                    borderRadius: AppRadius.large20,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
            ],
          ],
        ),
      ),
    );
  }
}
