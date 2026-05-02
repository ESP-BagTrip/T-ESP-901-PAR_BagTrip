import 'package:bagtrip/gen/colors.gen.dart';
import 'package:flutter/material.dart';

/// Centralized spacing tokens (logical pixels) and convenient EdgeInsets.
/// Use these constants throughout the app instead of magic numbers.

class AppSize {
  const AppSize._();

  static const double height42 = 42.0;
  static const double width42 = 42.0;
  static const double iconSizeHeight24 = 24.0;
  static const double boxSize8 = 8.0;
  static const double boxSize16 = 16.0;
}

class AppSpacing {
  const AppSpacing._();

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;

  /// Primary CTA vertical padding (Plan trip wizard).
  static const double space15 = 15.0;
  static const double space16 = 16.0;

  /// Horizontal margin for Plan trip wizard screens (Ive-style density).
  static const double space22 = 22.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;

  // Convenience EdgeInsets
  static const EdgeInsets allEdgeInsetSpace4 = EdgeInsets.all(space4);
  static const EdgeInsets allEdgeInsetSpace8 = EdgeInsets.all(space8);
  static const EdgeInsets allEdgeInsetSpace16 = EdgeInsets.all(space16);
  static const EdgeInsets allEdgeInsetSpace24 = EdgeInsets.all(space24);
  static const EdgeInsets allEdgeInsetSpace32 = EdgeInsets.all(space32);
  static const EdgeInsets allEdgeInsetSpace40 = EdgeInsets.all(space40);
  static const EdgeInsets allEdgeInsetSpace48 = EdgeInsets.all(space48);

  static const EdgeInsets onlyTopSpace8 = EdgeInsets.only(top: space8);
  static const EdgeInsets onlyBottomSpace8 = EdgeInsets.only(bottom: space8);
  static const EdgeInsets onlyLeftSpace8 = EdgeInsets.only(left: space8);
  static const EdgeInsets onlyRightSpace8 = EdgeInsets.only(right: space8);

  static const EdgeInsets onlyTopSpace16 = EdgeInsets.only(top: space16);
  static const EdgeInsets onlyBottomSpace16 = EdgeInsets.only(bottom: space16);
  static const EdgeInsets onlyLeftSpace16 = EdgeInsets.only(left: space16);
  static const EdgeInsets onlyRightSpace16 = EdgeInsets.only(right: space16);

  static const EdgeInsets horizontalSpace8 = EdgeInsets.symmetric(
    horizontal: space8,
  );
  static const EdgeInsets horizontalSpace16 = EdgeInsets.symmetric(
    horizontal: space16,
  );
  static const EdgeInsets verticalSpace8 = EdgeInsets.symmetric(
    vertical: space8,
  );
  static const EdgeInsets verticalSpace16 = EdgeInsets.symmetric(
    vertical: space16,
  );
  static const EdgeInsets verticalSpace15 = EdgeInsets.symmetric(
    vertical: space15,
  );

  // --- space12 EdgeInsets ---
  static const EdgeInsets allEdgeInsetSpace12 = EdgeInsets.all(space12);
  static const EdgeInsets horizontalSpace12 = EdgeInsets.symmetric(
    horizontal: space12,
  );
  static const EdgeInsets verticalSpace12 = EdgeInsets.symmetric(
    vertical: space12,
  );

  // --- Additional symmetric EdgeInsets ---
  static const EdgeInsets verticalSpace4 = EdgeInsets.symmetric(
    vertical: space4,
  );
  static const EdgeInsets verticalSpace24 = EdgeInsets.symmetric(
    vertical: space24,
  );
  static const EdgeInsets horizontalSpace4 = EdgeInsets.symmetric(
    horizontal: space4,
  );
  static const EdgeInsets horizontalSpace24 = EdgeInsets.symmetric(
    horizontal: space24,
  );
  static const EdgeInsets horizontalSpace22 = EdgeInsets.symmetric(
    horizontal: space22,
  );

  // --- Additional directional EdgeInsets ---
  static const EdgeInsets onlyTopSpace24 = EdgeInsets.only(top: space24);
  static const EdgeInsets onlyBottomSpace24 = EdgeInsets.only(bottom: space24);
}

/// Centralized corner radius tokens.
class AppRadius {
  const AppRadius._();

  /// Tiny — page-indicator dots, swatches.
  static const double cornerRadius2 = 2.0;

  /// Sub-tiny — bottom-sheet drag handle bars.
  static const double cornerRadius3 = 3.0;
  static const double cornerRaidus4 = 4.0;
  static const double cornerRaidus8 = 8.0;
  static const double cornerRaidus16 = 16.0;

  /// Context pill (Plan trip step header).
  static const double cornerRadius13 = 13.0;
  static const double cornerRadius20 = 20.0;
  static const double cornerRadius24 = 24.0;
  static const double cornerRadius28 = 28.0;
  static const double cornerRadius32 = 32.0;

  /// Bottom-sheet drag handle bar (40×4 surface). Was duplicated in
  /// every sheet as `BorderRadius.circular(2)`.
  static const BorderRadius handleBar = BorderRadius.all(
    Radius.circular(cornerRadius2),
  );

  /// Page indicator dots (paywall, onboarding carousels). Was
  /// `BorderRadius.circular(3)` repeated across each page-dot widget.
  static const BorderRadius dot = BorderRadius.all(
    Radius.circular(cornerRadius3),
  );

  static const BorderRadius small4 = BorderRadius.all(
    Radius.circular(cornerRaidus4),
  );
  static const BorderRadius medium8 = BorderRadius.all(
    Radius.circular(cornerRaidus8),
  );
  static const BorderRadius large16 = BorderRadius.all(
    Radius.circular(cornerRaidus16),
  );
  static const BorderRadius large13 = BorderRadius.all(
    Radius.circular(cornerRadius13),
  );
  static const BorderRadius large20 = BorderRadius.all(
    Radius.circular(cornerRadius20),
  );
  static const BorderRadius large24 = BorderRadius.all(
    Radius.circular(cornerRadius24),
  );
  static const BorderRadius large28 = BorderRadius.all(
    Radius.circular(cornerRadius28),
  );
  static const BorderRadius large32 = BorderRadius.all(
    Radius.circular(cornerRadius32),
  );

  /// Pilule (bords entièrement arrondis), comme dans la maquette.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Centralized elevation tokens. These replace the `BoxShadow(color:
/// ColorName.primary.withValues(alpha: 0.0x), ...)` duplicates that had
/// accumulated across ~30 card widgets (activity card, budget item card,
/// trip section card, flight card, etc.).
///
/// Use the pre-combined list constants (`AppShadows.card`, etc.) when you
/// just need "the standard card elevation" — or pick individual shadows
/// if you're building something bespoke.
class AppShadows {
  const AppShadows._();

  /// Soft primary-tinted drop shadow (8% alpha, 4px offset, 6px blur).
  /// Used as the main elevation of cards.
  static final BoxShadow cardPrimary = BoxShadow(
    color: ColorName.primary.withValues(alpha: 0.08),
    offset: const Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  );

  /// Ambient companion shadow (4% alpha, 2px offset, 4px blur).
  /// Usually paired with [cardPrimary] to ground the element.
  static final BoxShadow cardAmbient = BoxShadow(
    color: ColorName.primary.withValues(alpha: 0.04),
    offset: const Offset(0, 2),
    blurRadius: 4,
    spreadRadius: -1,
  );

  /// Standard card elevation: primary drop + ambient. This is what
  /// 90% of cards in the app actually want.
  static final List<BoxShadow> card = [cardPrimary, cardAmbient];
}

/// Centralized animation duration tokens. Replace
/// `Duration(milliseconds: 200)` / `300` / `600` scattered across the
/// codebase so tempo changes land everywhere at once.
class AppAnimationDurations {
  const AppAnimationDurations._();

  /// Micro interaction (150 ms) — tap ripples, icon flips.
  static const Duration microInteraction = Duration(milliseconds: 150);

  /// Quick (200 ms) — chip/button hover states, subtle reveals.
  static const Duration quick = Duration(milliseconds: 200);

  /// Standard (300 ms) — bottom sheet, list item mutations, the default
  /// Material transition.
  static const Duration standard = Duration(milliseconds: 300);

  /// Lengthy (600 ms) — hero transitions, longer celebratory animations.
  static const Duration lengthy = Duration(milliseconds: 600);
}
