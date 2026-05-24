import 'package:bagtrip/design/app_animations.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// A single budget option shown as a chip.
class BudgetOption {
  final String label;
  final String emoji;
  final String range;

  const BudgetOption({
    required this.label,
    required this.emoji,
    required this.range,
  });
}

/// A 2x2 grid of selectable budget chips with single selection.
class BudgetChipSelector extends StatelessWidget {
  final List<BudgetOption> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const BudgetChipSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipWidth = (constraints.maxWidth - AppSpacing.space12) / 2;

        return Wrap(
          spacing: AppSpacing.space12,
          runSpacing: AppSpacing.space12,
          children: [
            for (int i = 0; i < options.length; i++)
              SizedBox(
                width: chipWidth,
                child: _BudgetChip(
                  option: options[i],
                  isSelected: selectedIndex == i,
                  onTap: () {
                    AppHaptics.light();
                    onSelected(i);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BudgetChip extends StatelessWidget {
  final BudgetOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _BudgetChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.microInteraction,
        curve: AppAnimations.standardCurve,
        padding: AppSpacing.allEdgeInsetSpace12,
        decoration: BoxDecoration(
          color: isSelected ? ColorName.primaryLight : ColorName.surface,
          borderRadius: AppRadius.large16,
          border: Border.all(
            color: isSelected ? ColorName.primary : ColorName.primarySoftLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorName.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: AppSpacing.space8),
            Text(
              option.label,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: ColorName.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              option.range,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                color: ColorName.hint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
