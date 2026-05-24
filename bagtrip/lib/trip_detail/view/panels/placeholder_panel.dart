import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Temporary placeholder rendered by a panel while its full implementation
/// is pending. Each panel will swap this out with its real content in the
/// following sprint steps (4–7).
class PanelPlaceholder extends StatelessWidget {
  const PanelPlaceholder({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: ColorName.hint,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            const Text(
              'Coming soon',
              style: TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: ColorName.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
