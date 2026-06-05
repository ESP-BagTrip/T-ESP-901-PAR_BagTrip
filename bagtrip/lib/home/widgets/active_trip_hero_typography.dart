import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Title + date styles shared by the home active-trip card hero image and
/// [ReviewHero] on [ActiveTripProgrammeView].
abstract final class ActiveTripHeroTypography {
  static const city = TextStyle(
    fontFamily: FontFamily.dMSerifDisplay,
    fontSize: 30,
    fontWeight: FontWeight.w400,
    color: ColorName.surface,
  );

  static final subtitle = TextStyle(
    fontFamily: FontFamily.dMSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorName.surface.withValues(alpha: 0.82),
  );
}
