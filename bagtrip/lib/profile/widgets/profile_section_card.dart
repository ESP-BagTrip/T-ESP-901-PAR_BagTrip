import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Shared card style for profile sections (surface, border, shadows, padding).
/// Use [onTap] for tappable sections (e.g. experience personalization).
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.child, this.onTap});

  final Widget child;
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
    return Container(
      decoration: _decoration,
      padding: AppSpacing.allEdgeInsetSpace24,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: AppRadius.large16, child: child)
          : child,
    );
  }
}
