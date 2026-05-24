import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Teal uppercase section label with leading icon (item forms).
class FormSectionHeader extends StatelessWidget {
  const FormSectionHeader({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ColorName.secondary),
          const SizedBox(width: AppSpacing.space8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: ColorName.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
