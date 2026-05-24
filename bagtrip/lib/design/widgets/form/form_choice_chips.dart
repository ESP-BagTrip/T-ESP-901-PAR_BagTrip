import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class FormChoiceChipOption<T> {
  const FormChoiceChipOption({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
}

/// Single-select chips with item-form styling.
class FormChoiceChips<T> extends StatelessWidget {
  const FormChoiceChips({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<FormChoiceChipOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FormSectionHeader(label: label, icon: icon),
        Wrap(
          spacing: AppSpacing.space8,
          runSpacing: AppSpacing.space8,
          children: options.map((opt) {
            final isSelected = opt.value == value;
            return GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: AppAnimationDurations.quick,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space12,
                  vertical: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorName.primaryTrueDark
                      : ColorName.surfaceLight,
                  borderRadius: AppRadius.medium12,
                  border: Border.all(
                    color: isSelected
                        ? ColorName.primaryTrueDark
                        : ColorName.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.icon != null) ...[
                      Icon(
                        opt.icon,
                        size: 16,
                        color: isSelected
                            ? ColorName.surface
                            : (opt.iconColor ?? ColorName.textMutedLight),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? ColorName.surface
                            : ColorName.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
