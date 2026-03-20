import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class ActiveTripHero extends StatelessWidget {
  final Trip trip;
  final int currentDay;
  final int totalDays;
  final String? weatherSummary;

  const ActiveTripHero({
    super.key,
    required this.trip,
    required this.currentDay,
    required this.totalDays,
    this.weatherSummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination = trip.destinationName ?? trip.title ?? '';
    final hasCover =
        trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty;

    return Hero(
      tag: 'trip-${trip.id}',
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
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  if (hasCover)
                    Image.network(
                      trip.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _GradientPlaceholder(),
                    )
                  else
                    const _GradientPlaceholder(),

                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                  ),

                  // Chevron affordance
                  Positioned(
                    top: AppSpacing.space16,
                    right: AppSpacing.space16,
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 24,
                    ),
                  ),

                  // Content overlay
                  Positioned(
                    left: AppSpacing.space16,
                    right: AppSpacing.space16,
                    bottom: AppSpacing.space16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Destination name
                        Text(
                          destination.isNotEmpty
                              ? l10n.homeActiveTripTitle(destination)
                              : destination,
                          style: const TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.space8),

                        // Day pill + weather
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space12,
                                vertical: AppSpacing.space4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                l10n.homeActiveTripDay(currentDay, totalDays),
                                style: const TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (weatherSummary != null) ...[
                              const SizedBox(width: AppSpacing.space12),
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.space4),
                              Text(
                                weatherSummary!,
                                style: TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColorName.primary, ColorName.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.flight_rounded,
        color: ColorName.surface.withValues(alpha: 0.3),
        size: 48,
      ),
    );
  }
}
