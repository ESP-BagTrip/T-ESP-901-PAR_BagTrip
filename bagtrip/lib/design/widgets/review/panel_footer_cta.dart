import 'package:flutter/material.dart';

/// Controls the visibility of a [PanelFooterCta].
///
/// Owns an [AnimationController] with a value in `[0, 1]` (1 = visible).
/// Pass it both to [PanelFooterCta] (to drive the rendering) and to a
/// [NotificationListener] via [handleScrollNotification] (to auto-hide on
/// scroll-down / auto-show on scroll-up).
///
/// Call [show] / [hide] imperatively from the parent (e.g. on tab change).
class PanelFooterCtaController extends ChangeNotifier {
  PanelFooterCtaController({
    required TickerProvider vsync,
    this.duration = const Duration(milliseconds: 280),
    this.scrollDeltaThreshold = 3,
  }) : _controller = AnimationController(
         vsync: vsync,
         duration: duration,
         value: 1,
       ) {
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  final Duration duration;
  final double scrollDeltaThreshold;

  final AnimationController _controller;
  late final CurvedAnimation _curve;

  Animation<double> get animation => _curve;

  void show() => _controller.forward();
  void hide() => _controller.reverse();

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta;
    if (delta == null || delta.abs() < scrollDeltaThreshold) return false;
    if (delta > 0) {
      hide();
    } else {
      show();
    }
    return false;
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }
}

/// Scroll-reactive footer wrapper. Fades and collapses its [child] when the
/// driving [controller] reverses.
class PanelFooterCta extends StatelessWidget {
  const PanelFooterCta({
    super.key,
    required this.controller,
    required this.child,
  });

  final PanelFooterCtaController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation,
      builder: (context, _) {
        return IgnorePointer(
          ignoring: controller.animation.value < 0.01,
          child: FadeTransition(
            opacity: controller.animation,
            child: SizeTransition(
              sizeFactor: controller.animation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
