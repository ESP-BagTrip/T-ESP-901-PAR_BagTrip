import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Caps label + percentage + thin progress bar. Shared between the Essentials
/// panel (inside `TripDetailView`) and the routed `/baggage` subpage so both
/// surfaces render the exact same packed progress affordance.
class ProgressStrip extends StatelessWidget {
  const ProgressStrip({super.key, required this.label, required this.progress});

  /// Caps text on the left (e.g. "4 OF 12 PACKED").
  final String label;

  /// Progress ratio in the `[0, 1]` range.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ColorName.hint,
                ),
              ),
            ),
            Text(
              '${(clamped * 100).round()}%',
              style: const TextStyle(
                fontFamily: FontFamily.dMSerifDisplay,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ColorName.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        ClipRRect(
          borderRadius: AppRadius.pill,
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 6,
            backgroundColor: ColorName.primarySoftLight,
            valueColor: const AlwaysStoppedAnimation(ColorName.secondary),
          ),
        ),
      ],
    );
  }
}
