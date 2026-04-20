import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const Color _nowLineTeal = Color(0xFF34B7A4);

/// Fills a gap on the timeline between scheduled items (styled for active trip).
class NowIndicatorRow extends StatelessWidget {
  const NowIndicatorRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spineColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.6);

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(child: Container(width: 2, color: spineColor)),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _nowLineTeal,
                  ),
                ),
                Expanded(child: Container(width: 2, color: spineColor)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: _nowLineTeal.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space8),
                  Text(
                    l10n.timelineNow,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _nowLineTeal,
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
