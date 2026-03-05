import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
      ),
      padding: padding,
      child: child,
    );
  }
}
