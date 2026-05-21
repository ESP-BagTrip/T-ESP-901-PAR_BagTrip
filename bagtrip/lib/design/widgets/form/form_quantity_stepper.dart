import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Quantity stepper inside a micro-label field container.
class FormQuantityStepper extends StatelessWidget {
  const FormQuantityStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.decreaseTooltip,
    this.increaseTooltip,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final String? decreaseTooltip;
  final String? increaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: ColorName.surfaceLight,
        borderRadius: AppRadius.medium12,
        border: Border.all(color: ColorName.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: ColorName.textMutedLight,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                tooltip: decreaseTooltip,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ColorName.primaryTrueDark,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                tooltip: increaseTooltip,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: ColorName.primaryTrueDark),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
