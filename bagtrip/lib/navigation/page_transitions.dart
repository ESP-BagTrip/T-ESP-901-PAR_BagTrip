import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Builds a page with a platform-appropriate transition.
///
/// Android: smooth slide-from-right + fade (Material).
/// iOS: native [CupertinoPageRoute] slide-from-right with swipe-back.
CustomTransitionPage<T> buildSlideTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 350),
  Curve curve = Curves.easeOutCubic,
}) {
  if (AdaptivePlatform.isIOS) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      },
    );
  }

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
    },
  );
}

/// Fade transition for hero-style navigation (card → detail).
/// The actual hero element is animated by [Hero] widgets; this fades the page.
CustomTransitionPage<T> buildHeroTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppAnimations.cardTransition,
    reverseTransitionDuration: AppAnimations.cardTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppAnimations.standardCurve,
        ),
        child: child,
      );
    },
  );
}

/// Slide transition for wizard/multi-step flows.
/// Cupertino on iOS, Material slide+fade on Android.
CustomTransitionPage<T> buildWizardTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  if (AdaptivePlatform.isIOS) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoPageTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: false,
          child: child,
        );
      },
    );
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppAnimations.standardCurve,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
