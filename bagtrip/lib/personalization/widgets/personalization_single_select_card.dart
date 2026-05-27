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
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? ColorName.secondaryLight.withValues(alpha: 0.3)
          : theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: AppRadius.large16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large16,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.hovered)) {
            return ColorName.secondary.withValues(alpha: 0.14);
          }
          return null;
        }),
        child: Container(
          padding: AppSpacing.allEdgeInsetSpace16,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large16,
            border: Border.all(
              color: selected
                  ? ColorName.secondary
                  : theme.colorScheme.outlineVariant,
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
                color: selected
                    ? ColorName.secondary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
