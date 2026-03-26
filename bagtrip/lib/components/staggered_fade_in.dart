import 'package:flutter/material.dart';

class StaggeredFadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration duration;

  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final totalDelay = baseDelay * index;
    final totalDuration = totalDelay + duration;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: totalDuration,
      // Linear curve needed: easeOutCubic applied per-segment in builder
      builder: (context, rawValue, child) {
        // Compute progress within the animation window (after delay)
        final delayFraction =
            totalDelay.inMilliseconds /
            totalDuration.inMilliseconds.clamp(1, double.infinity);
        final double progress;
        if (rawValue <= delayFraction) {
          progress = 0;
        } else {
          progress = Curves.easeOutCubic.transform(
            ((rawValue - delayFraction) / (1 - delayFraction)).clamp(0, 1),
          );
        }

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
