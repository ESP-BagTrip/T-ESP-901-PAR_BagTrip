import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Step indicator: current step is an elongated pill with gradient; others are grey dots.
class PremiumStepIndicator extends StatelessWidget {
  const PremiumStepIndicator({
    super.key,
    required this.current,
    required this.total,
    this.showLabel = false,

    /// If set, the current step dot uses this color (e.g. success green for final step).
    this.currentStepColor,
  });

  final int current;
  final int total;
  final bool showLabel;
  final Color? currentStepColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(total, (i) {
          final isCurrent = i == current - 1;
          return Padding(
            padding: EdgeInsets.only(
              right: i < total - 1 ? AppSpacing.space8 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isCurrent ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: isCurrent
                    ? LinearGradient(
                        colors: currentStepColor != null
                            ? [
                                currentStepColor!,
                                currentStepColor!.withValues(alpha: 0.85),
                              ]
                            : const [ColorName.primary, ColorName.secondary],
                      )
                    : null,
                color: isCurrent
                    ? null
                    : PersonalizationColors.textTertiary.withValues(
                        alpha: 0.35,
                      ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: (currentStepColor ?? ColorName.secondary)
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
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
