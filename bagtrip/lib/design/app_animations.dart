import 'package:flutter/animation.dart';

/// Centralized animation constants — named by intent, not value.
abstract final class AppAnimations {
  /// Emphasis curve without excessive bounce.
  static const Curve springCurve = Curves.easeOutBack;

  /// Standard transition curve (panels, lists, fades).
  static const Curve standardCurve = Curves.easeOutCubic;

  /// Delay between staggered list items.
  static const Duration staggerDelay = Duration(milliseconds: 80);

  /// Hero transitions, card enter/exit.
  static const Duration cardTransition = Duration(milliseconds: 350);

  /// Tap feedback, color changes, toggles.
  static const Duration microInteraction = Duration(milliseconds: 200);

  /// Step transitions in wizard flows.
  static const Duration wizardTransition = Duration(milliseconds: 300);

  /// Empty states, halo fade-in.
  static const Duration fadeIn = Duration(milliseconds: 400);

  /// Wizard shell: title row + step indicator slide/fade in.
  static const Duration fadeDown = Duration(milliseconds: 360);

  /// Badge scale-in (dates step).
  static const Duration badgeScaleIn = Duration(milliseconds: 320);

  /// Quick scale/press feedback.
  static const Duration pressFeedback = Duration(milliseconds: 150);
}
