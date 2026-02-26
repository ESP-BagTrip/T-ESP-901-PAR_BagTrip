import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Card for Planifier page: icon container (left), title and description (right).
/// Uses the same decoration as profile section cards.
class PlanifierCard extends StatelessWidget {
  const PlanifierCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final Widget icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  static BoxDecoration get _decoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.large16,
    border: Border.all(color: ColorName.primarySoftLight),
    boxShadow: [
      BoxShadow(
        color: ColorName.primary.withValues(alpha: 0.08),
        offset: const Offset(0, 4),
        blurRadius: 6,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: ColorName.primary.withValues(alpha: 0.04),
        offset: const Offset(0, 2),
        blurRadius: 4,
        spreadRadius: -1,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large16,
          child: Padding(
            padding: AppSpacing.allEdgeInsetSpace24,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTrueDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
