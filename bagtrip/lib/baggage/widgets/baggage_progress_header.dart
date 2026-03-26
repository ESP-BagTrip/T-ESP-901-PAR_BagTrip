import 'dart:math';

import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BaggageProgressHeader extends StatelessWidget {
  final int packedCount;
  final int totalCount;

  const BaggageProgressHeader({
    super.key,
    required this.packedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = totalCount > 0 ? packedCount / totalCount : 0.0;

    return Container(
      padding: AppSpacing.allEdgeInsetSpace24,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.large16,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ProgressArcPainter(
                ratio: ratio,
                trackColor: AppColors.border,
                progressColor: AppColors.success,
              ),
              child: Center(
                child: Text(
                  '$packedCount',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.baggagePackedCount(packedCount, totalCount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (totalCount > 0)
                  ClipRRect(
                    borderRadius: AppRadius.pill,
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double ratio;
  final Color trackColor;
  final Color progressColor;

  _ProgressArcPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 4;
    const startAngle = -pi / 2;
    const sweepFull = 2 * pi;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepFull,
      false,
      trackPaint,
    );

    // Progress
    if (ratio > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * ratio,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}
