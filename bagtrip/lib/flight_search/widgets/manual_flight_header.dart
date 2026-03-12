import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Header for manual flight form: label ("Quel est votre prochain voyage") + "Find your flight".
class ManualFlightHeader extends StatelessWidget {
  const ManualFlightHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.diamond_rounded,
              size: 14,
              color: ColorName.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.whereNextLabel,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ColorName.hint,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.findYourFlightTitle,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: ColorName.primaryTrueDark,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
