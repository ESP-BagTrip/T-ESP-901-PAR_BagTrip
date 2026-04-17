import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

/// Navy-tinted hero: eyebrow, serif destination, day badge (weather lives below).
class ActiveTripHero extends StatelessWidget {
  final Trip trip;
  final int currentDay;
  final int totalDays;

  const ActiveTripHero({
    super.key,
    required this.trip,
    required this.currentDay,
    required this.totalDays,
  });

  static const Color _navy = Color(0xFF1A2B48);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination = trip.destinationName ?? trip.title ?? '';
    final hasCover =
        trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty;

    return Hero(
      tag: 'active-trip-${trip.id}',
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            AppHaptics.light();
            TripHomeRoute(tripId: trip.id).go(context);
          },
          child: ClipRRect(
            borderRadius: AppRadius.large24,
            child: SizedBox(
              width: double.infinity,
              height: 240,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    OptimizedImage.tripCover(
                      trip.coverImageUrl!,
                      errorWidget: const _NavyPlaceholder(),
                    )
                  else
                    const _NavyPlaceholder(),
                  // Navy wash + bottom fade
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _navy.withValues(alpha: 0.55),
                          _navy.withValues(alpha: 0.35),
                          _navy.withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: -50,
                    child: IgnorePointer(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.space16,
                    right: AppSpacing.space16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space12,
                        vertical: AppSpacing.space8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        l10n.homeActiveTripDay(currentDay, totalDays),
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.space24,
                    right: AppSpacing.space24,
                    bottom: AppSpacing.space24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.homeActiveTripEyebrow,
                          style: TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Text(
                          destination.isNotEmpty
                              ? destination
                              : l10n.tripCardNoDestination,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 34,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.space16,
                    right: AppSpacing.space16,
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavyPlaceholder extends StatelessWidget {
  const _NavyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2B48), Color(0xFF2D4A6F)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.flight_rounded,
        color: Colors.white.withValues(alpha: 0.2),
        size: 56,
      ),
    );
  }
}
