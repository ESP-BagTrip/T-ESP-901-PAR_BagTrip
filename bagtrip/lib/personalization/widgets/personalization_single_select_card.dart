import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class PersonalizationSingleSelectCard extends StatelessWidget {
  const PersonalizationSingleSelectCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected
              ? AppColors.secondaryLight.withValues(alpha: 0.3)
              : AppColors.surface,
      borderRadius: AppRadius.large16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace16,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large16,
            border: Border.all(
              color:
                  selected ? AppColors.secondary : ColorName.primarySoftLight,
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
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color:
                    selected ? AppColors.secondary : AppColors.textMutedLight,
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTrueDark,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
