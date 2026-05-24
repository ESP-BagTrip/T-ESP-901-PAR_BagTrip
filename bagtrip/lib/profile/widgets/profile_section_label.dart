import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Uppercase section title for grouped profile menu blocks.
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.space4,
        bottom: AppSpacing.space8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: ColorName.hint,
        ),
      ),
    );
  }
}
