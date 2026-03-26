import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NowIndicatorRow extends StatelessWidget {
  const NowIndicatorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline spine with red dot
          SizedBox(
            width: 32,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space8),

          // Red line + label
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 1, color: Colors.red.shade400),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    l10n.timelineNow,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
