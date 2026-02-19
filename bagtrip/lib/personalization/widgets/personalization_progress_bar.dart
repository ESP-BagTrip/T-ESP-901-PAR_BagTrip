import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

class PersonalizationProgressBar extends StatelessWidget {
  const PersonalizationProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(total, (i) {
              final filled = i < current;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color:
                        filled
                            ? AppColors.secondary
                            : AppColors.primarySoftLight,
                    borderRadius: AppRadius.small4,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Text(
          '$current/$total',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
        ),
      ],
    );
  }
}
