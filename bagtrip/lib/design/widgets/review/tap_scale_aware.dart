import 'package:flutter/material.dart';

/// Wraps a tappable widget with a subtle tap-scale feedback (Apple-style
/// 0.97 during press, returns to 1.0 on release).
///
/// Use on interactive cards where the existing `InkWell` ripple is too
/// heavy — boarding pass cards, hotel cards, activity tiles. The scale
/// replaces the ripple, so wrap the `Material` + `InkWell` body as a
/// single child.
///
/// Respects `MediaQuery.disableAnimations` — snaps directly without the
/// scale transition when reduce-motion is active.
class TapScaleAware extends StatefulWidget {
  const TapScaleAware({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale applied during press (default 0.97 — Apple's card interaction).
  final double scale;

  /// Duration of the scale transition.
  final Duration duration;

  @override
  State<TapScaleAware> createState() => _TapScaleAwareState();
}

class _TapScaleAwareState extends State<TapScaleAware>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
      lowerBound: widget.scale,
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateDown() {
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.reverse();
  }

  void _animateUp() {
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _animateDown(),
      onTapUp: widget.onTap == null ? null : (_) => _animateUp(),
      onTapCancel: widget.onTap == null ? null : _animateUp,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}
