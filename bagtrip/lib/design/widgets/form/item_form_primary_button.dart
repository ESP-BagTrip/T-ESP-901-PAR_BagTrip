import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Standard secondary CTA for item-form bottom sheets.
class ItemFormPrimaryButton extends StatelessWidget {
  const ItemFormPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      minimumSize: const Size.fromHeight(52),
      backgroundColor: ColorName.secondary,
      disabledBackgroundColor: ColorName.secondary.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.large16),
    );

    final textStyle = const TextStyle(
      fontFamily: FontFamily.b612,
      fontWeight: FontWeight.bold,
      color: ColorName.surface,
    );

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, color: ColorName.surface, size: 20),
        label: Text(label, style: textStyle),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Text(label, style: textStyle),
    );
  }
}
