import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class PersonalizationSelectCard extends StatelessWidget {
  const PersonalizationSelectCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space16,
            horizontal: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : ColorName.primarySoftLight,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.06),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: AppSpacing.space8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTrueDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
