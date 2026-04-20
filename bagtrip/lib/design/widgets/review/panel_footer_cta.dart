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

/// Body + sticky footer scaffold that wires up the scroll-reactive
/// behavior of [PanelFooterCta] without the caller having to compose a
/// [NotificationListener] manually.
///
/// ```dart
/// ScrollReactiveCtaScaffold(
///   controller: _footerController,
///   body: DensityAwareListView(...),
///   footer: PillCtaButton(label: 'Add flight', onTap: ...),
/// )
/// ```
///
/// When `footer == null`, the scaffold renders only the body (useful for
/// read-only or archive states where no CTA should appear).
class ScrollReactiveCtaScaffold extends StatelessWidget {
  const ScrollReactiveCtaScaffold({
    super.key,
    required this.controller,
    required this.body,
    this.footer,
  });

  final PanelFooterCtaController controller;
  final Widget body;

  /// The footer widget (usually a [PillCtaButton]). When null, no footer
  /// is rendered.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final listener = NotificationListener<ScrollNotification>(
      onNotification: controller.handleScrollNotification,
      child: body,
    );
    if (footer == null) return listener;
    return Stack(
      children: [
        Positioned.fill(child: listener),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PanelFooterCta(controller: controller, child: footer!),
            ),
          ),
        ),
      ],
    );
  }
}
