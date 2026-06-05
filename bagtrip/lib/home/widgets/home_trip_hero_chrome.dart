import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/trip_cover_hero_overlay.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

export 'package:bagtrip/design/widgets/review/trip_cover_hero_overlay.dart'
    show TripCoverHeroFallback, TripCoverHeroScrim;

/// @nodoc — prefer [TripCoverHeroFallback].
typedef HomeTripHeroCoverFallback = TripCoverHeroFallback;

/// @nodoc — prefer [TripCoverHeroScrim].
typedef HomeTripHeroCoverScrim = TripCoverHeroScrim;

/// Semi-transparent pill chrome for labels on dark hero imagery.
class HomeTripHeroPill extends StatelessWidget {
  const HomeTripHeroPill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.surface.withValues(alpha: 0.1),
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: 6,
        ),
        child: child,
      ),
    );
  }
}

class HomeTripHeroEyebrowPill extends StatelessWidget {
  const HomeTripHeroEyebrowPill({super.key, required this.label});

  final String label;

  static const _labelStyle = TextStyle(
    fontFamily: FontFamily.dMSans,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: ColorName.surface,
    letterSpacing: 1,
  );

  @override
  Widget build(BuildContext context) {
    return HomeTripHeroPill(child: Text(label, style: _labelStyle));
  }
}

class HomeTripHeroCountdownPill extends StatelessWidget {
  const HomeTripHeroCountdownPill({super.key, required this.label});

  final String label;

  static const _labelStyle = TextStyle(
    fontFamily: FontFamily.dMSans,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: ColorName.surface,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ColorName.secondary,
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: 6,
        ),
        child: Text(label, style: _labelStyle),
      ),
    );
  }
}

class HomeTripTravelersPill extends StatelessWidget {
  const HomeTripTravelersPill({super.key, required this.label});

  final String label;

  static const _labelStyle = TextStyle(
    fontFamily: FontFamily.dMSans,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: ColorName.surface,
  );

  @override
  Widget build(BuildContext context) {
    return HomeTripHeroPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline_rounded,
            size: 14,
            color: ColorName.surface.withValues(alpha: 0.95),
          ),
          const SizedBox(width: AppSpacing.space4),
          Text(label, style: _labelStyle),
        ],
      ),
    );
  }
}
