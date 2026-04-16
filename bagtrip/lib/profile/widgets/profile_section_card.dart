import 'package:bagtrip/design/tokens.dart';
import 'package:flutter/material.dart';

/// Shared card style for profile sections (surface, border, shadows, padding).
/// Use [onTap] for tappable sections (e.g. experience personalization).
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppShadows.card,
      ),
      padding: AppSpacing.allEdgeInsetSpace24,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: AppRadius.large16, child: child)
          : child,
    );
  }
}
