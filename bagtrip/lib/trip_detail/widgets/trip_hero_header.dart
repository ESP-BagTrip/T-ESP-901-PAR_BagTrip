import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/widgets/trip_status_badge.dart';
import 'package:flutter/material.dart';

enum TripHeroState { upcoming, ongoing, completed }

class TripHeroHeader extends StatelessWidget {
  final Trip trip;
  final String dateRange;
  final int? daysUntilTrip;
  final int? currentDay;
  final int totalDays;
  final bool isCompleted;
  final bool isOngoing;
  final VoidCallback? onTapDates;
  final bool isEditable;

  const TripHeroHeader({
    super.key,
    required this.trip,
    required this.dateRange,
    this.daysUntilTrip,
    this.currentDay,
    required this.totalDays,
    required this.isCompleted,
    required this.isOngoing,
    this.onTapDates,
    this.isEditable = false,
  });

  TripHeroState get _state {
    if (isCompleted) return TripHeroState.completed;
    if (isOngoing && currentDay != null) return TripHeroState.ongoing;
    return TripHeroState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    final hasCover =
        trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty;

    return Hero(
      tag: 'trip-${trip.id}',
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 — Background image or gradient placeholder
            if (hasCover)
              OptimizedImage.tripCover(
                trip.coverImageUrl!,
                errorWidget: const _GradientPlaceholder(),
              )
            else
              const _GradientPlaceholder(),

            // Layer 2 — Three-stop gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x33000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // Layer 3 — Content
            Positioned(
              left: AppSpacing.space24,
              right: AppSpacing.space24,
              bottom: 56,
              child: _HeroContent(
                trip: trip,
                dateRange: dateRange,
                state: _state,
                daysUntilTrip: daysUntilTrip,
                currentDay: currentDay,
                totalDays: totalDays,
                onTapDates: onTapDates,
                isEditable: isEditable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  final Trip trip;
  final String dateRange;
  final TripHeroState state;
  final int? daysUntilTrip;
  final int? currentDay;
  final int totalDays;
  final VoidCallback? onTapDates;
  final bool isEditable;

  const _HeroContent({
    required this.trip,
    required this.dateRange,
    required this.state,
    this.daysUntilTrip,
    this.currentDay,
    required this.totalDays,
    this.onTapDates,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Destination + status badge
        Row(
          children: [
            if (trip.destinationName != null) ...[
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  trip.destinationName!,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Spacer(),
            TripStatusBadge(status: trip.status),
          ],
        ),

        // Date range
        if (dateRange.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTapDates,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  dateRange,
                  style: const TextStyle(
                    fontFamily: FontFamily.b612,
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                if (isEditable) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Contextual state pill
        const SizedBox(height: 12),
        _StatePill(
          state: state,
          daysUntilTrip: daysUntilTrip,
          currentDay: currentDay,
          totalDays: totalDays,
        ),
      ],
    );
  }
}

class _StatePill extends StatelessWidget {
  final TripHeroState state;
  final int? daysUntilTrip;
  final int? currentDay;
  final int totalDays;

  const _StatePill({
    required this.state,
    this.daysUntilTrip,
    this.currentDay,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (IconData icon, String label) = switch (state) {
      TripHeroState.upcoming => (
        Icons.schedule_rounded,
        l10n.nextTripCountdown(daysUntilTrip ?? 0),
      ),
      TripHeroState.ongoing => (
        Icons.play_circle_outline,
        l10n.homeActiveTripDay(currentDay!, totalDays),
      ),
      TripHeroState.completed => (
        Icons.check_circle_outline,
        l10n.statusCompleted,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space4 + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: AppSpacing.space4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
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
