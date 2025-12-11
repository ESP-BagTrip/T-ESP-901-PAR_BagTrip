import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';

class FlightSearchResultShimmer extends StatelessWidget {
  const FlightSearchResultShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Date Selector Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: ColorName.primaryLight,
                        borderRadius: AppRadius.large16,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: ColorName.primaryLight,
                      borderRadius: AppRadius.large16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          // Filter Button Shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: ColorName.primaryLight,
                borderRadius: AppRadius.large16,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          // Flight Cards Shimmer
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 120,
                  margin: AppSpacing.onlyBottomSpace16,
                  decoration: const BoxDecoration(
                    color: ColorName.primaryLight,
                    borderRadius: AppRadius.large16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
