import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Minimal step indicator: dots for each step, current step highlighted with accent.
class PremiumStepIndicator extends StatelessWidget {
  const PremiumStepIndicator({
    super.key,
    required this.current,
    required this.total,
    this.showLabel = false,
  });

  final int current;
  final int total;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(total, (i) {
          final isActive = i < current;
          final isCurrent = i == current - 1;
          return Padding(
            padding: EdgeInsets.only(
              right: i < total - 1 ? AppSpacing.space8 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isCurrent ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    isActive
                        ? PersonalizationColors.accentBlue
                        : PersonalizationColors.cardBorderUnselected,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.space8),
          Text(
            '$current / $total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: PersonalizationColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
