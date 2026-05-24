import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/design/widgets/form/form_quantity_stepper.dart';
import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/micro_label_field.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/baggage_category.dart';
import 'package:flutter/material.dart';

class BaggageItemFormContent extends StatelessWidget {
  const BaggageItemFormContent({
    super.key,
    required this.nameController,
    required this.quantity,
    required this.category,
    required this.onQuantityChanged,
    required this.onCategoryChanged,
    this.nameValidator,
  });

  final TextEditingController nameController;
  final int quantity;
  final String category;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onCategoryChanged;
  final FormFieldValidator<String>? nameValidator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FormSectionHeader(
          label: l10n.baggageItemName,
          icon: Icons.luggage_outlined,
        ),
        MicroLabelField(
          label: l10n.baggageItemName,
          controller: nameController,
          hint: l10n.baggageItemName,
          prefixIcon: const Icon(
            Icons.luggage_outlined,
            size: 18,
            color: ColorName.hint,
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: nameValidator,
        ),
        const SizedBox(height: AppSpacing.space24),
        FormSectionHeader(
          label: l10n.baggageCategoryLabel,
          icon: Icons.category_outlined,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormQuantityStepper(
                label: l10n.baggageQuantityLabel,
                value: quantity,
                onChanged: onQuantityChanged,
                decreaseTooltip: l10n.decreaseQuantityTooltip,
                increaseTooltip: l10n.increaseQuantityTooltip,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space12),
        Wrap(
          spacing: AppSpacing.space8,
          runSpacing: AppSpacing.space8,
          children: BaggageCategory.values.map((cat) {
            final isSelected = category == cat.apiValue;
            return GestureDetector(
              onTap: () {
                AppHaptics.light();
                onCategoryChanged(cat.apiValue);
              },
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
                    Icon(
                      cat.icon,
                      size: 14,
                      color: isSelected ? ColorName.surface : cat.color,
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Text(
                      cat.label(l10n),
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
