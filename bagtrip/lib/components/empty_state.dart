import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.allEdgeInsetSpace24,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.hint),
            const SizedBox(height: AppSpacing.space16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.hint),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.space8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMutedLight,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.space16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
