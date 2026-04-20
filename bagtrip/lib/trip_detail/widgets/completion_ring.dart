import 'dart:math' as math;

import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Small circular completion indicator rendered in the editor hero's
/// `trailing` slot. Replaces the legacy `TripCompletionBar`.
///
/// Animates the stroke sweep when [percentage] changes so the state is
/// perceptible without being noisy.
class CompletionRing extends StatelessWidget {
  const CompletionRing({
    super.key,
    required this.percentage,
    this.size = 56,
    this.strokeWidth = 4,
    this.color = ColorName.surface,
    this.backgroundColor,
    this.onTap,
    this.duration = const Duration(milliseconds: 600),
  });

  /// 0–100. Values outside the range are clamped.
  final int percentage;

  final double size;
  final double strokeWidth;

  /// Foreground (progress) color. Defaults to a light tone that reads on the
  /// dark hero background.
  final Color color;

  /// Track color. Defaults to a translucent white for the hero background.
  final Color? backgroundColor;

  /// Optional tap — used by the editor to expose a "jump to incomplete
  /// section" sheet.
  final VoidCallback? onTap;

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);
    final track = backgroundColor ?? Colors.white.withValues(alpha: 0.2);

    final ring = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped / 100),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: color,
              backgroundColor: track,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Text(
                '$clamped%',
                style: TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (onTap == null) return ring;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ring,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final track = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweep = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      sweep,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.backgroundColor != backgroundColor ||
      old.strokeWidth != strokeWidth;
}
