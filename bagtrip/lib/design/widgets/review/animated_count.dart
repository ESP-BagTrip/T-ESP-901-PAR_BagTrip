import 'package:flutter/material.dart';

/// Tweens an integer value when it changes, used in hero meta lines
/// ("5 activities → 6 activities" animates the 5 → 6 transition).
///
/// The text around the number is owned by the caller via [formatter]:
/// ```dart
/// AnimatedCount(
///   value: activities.length,
///   formatter: (n) => '$n activities · 8h planned',
/// )
/// ```
///
/// Respects `MediaQuery.disableAnimations` — when accessibility
/// reduce-motion is enabled, the value snaps to its target immediately.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  /// Target integer value.
  final int value;

  /// Builds the surrounding text from the animated integer.
  final String Function(int) formatter;

  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> {
  late int _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previous = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.of(context).disableAnimations;
    if (disabled || _previous == widget.value) {
      return Text(widget.formatter(widget.value), style: widget.style);
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.value),
      tween: Tween<double>(
        begin: _previous.toDouble(),
        end: widget.value.toDouble(),
      ),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, v, _) {
        return Text(widget.formatter(v.round()), style: widget.style);
      },
    );
  }
}
