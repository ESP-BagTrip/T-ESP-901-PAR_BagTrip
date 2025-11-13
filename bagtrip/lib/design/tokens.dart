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
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Convenience EdgeInsets
  static const EdgeInsets allEdgeInsetSpace4 = EdgeInsets.all(space4);
  static const EdgeInsets allEdgeInsetSpace8 = EdgeInsets.all(space8);
  static const EdgeInsets allEdgeInsetSpace16 = EdgeInsets.all(space16);
  static const EdgeInsets allEdgeInsetSpace24 = EdgeInsets.all(space24);
  static const EdgeInsets allEdgeInsetSpace32 = EdgeInsets.all(space32);

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
}

/// Centralized corner radius tokens.
class AppRadius {
  const AppRadius._();

  static const double cornerRaidus4 = 4.0;
  static const double cornerRaidus8 = 8.0;
  static const double cornerRaidus16 = 16.0;

  static const BorderRadius small4 = BorderRadius.all(
    Radius.circular(cornerRaidus4),
  );
  static const BorderRadius medium8 = BorderRadius.all(
    Radius.circular(cornerRaidus8),
  );
  static const BorderRadius large16 = BorderRadius.all(
    Radius.circular(cornerRaidus16),
  );
}
