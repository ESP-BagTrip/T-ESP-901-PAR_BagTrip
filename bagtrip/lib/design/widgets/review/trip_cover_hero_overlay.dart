import 'package:flutter/material.dart';

/// Gradient placeholder when a trip cover is missing or fails to load.
class TripCoverHeroFallback extends StatelessWidget {
  const TripCoverHeroFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B48), Color(0xFF2D4A6F)],
        ),
      ),
    );
  }
}

/// Navy darkening scrim over trip cover imagery (home active card, programme hero).
class TripCoverHeroScrim extends StatelessWidget {
  const TripCoverHeroScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A2B48).withValues(alpha: 0.5),
            const Color(0xFF1A2B48).withValues(alpha: 0.85),
          ],
        ),
      ),
    );
  }
}
