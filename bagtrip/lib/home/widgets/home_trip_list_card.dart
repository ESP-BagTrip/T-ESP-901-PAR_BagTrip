import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/home/widgets/home_trip_hero_chrome.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:flutter/material.dart';

class HomeTripListSection extends StatelessWidget {
  final String title;
  final List<Trip> trips;
  final bool compactHeader;

  const HomeTripListSection({
    super.key,
    required this.title,
    required this.trips,
    this.compactHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compactHeader
              ? const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.textMutedLight,
                  letterSpacing: 1.2,
                )
              : const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorName.primaryTrueDark,
                ),
        ),
        const SizedBox(height: AppSpacing.space12),
        ...trips.map(
          (trip) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space12),
            child: HomeTripListCard(trip: trip),
          ),
        ),
      ],
    );
  }
}

class HomeTripListCard extends StatelessWidget {
  static const Color _frameColor = ColorName.surface;
  static const double _borderWidth = 1.5;

  final Trip trip;

  const HomeTripListCard({super.key, required this.trip});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'janv.',
      'fevr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'aout',
      'sept.',
      'oct.',
      'nov.',
      'dec.',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _dateRange() {
    final start = _formatDate(trip.startDate);
    final end = _formatDate(trip.endDate);
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  String _deadlineLabel(AppLocalizations l10n) {
    if (trip.status == TripStatus.ongoing) return l10n.tripStatusOngoing;
    final start = trip.startDate;
    if (start == null) return l10n.tripStatusPlanned;
    final now = DateTime.now();
    final days = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= 0) return l10n.timelineNow;
    return l10n.nextTripCountdown(days);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination =
        trip.destinationName ?? trip.title ?? l10n.myTripFallback;
    final progress = tripCompletion(trip).clamp(0, 100);
    final dateRangeText = _dateRange();
    final hasCover =
        trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty;
    final travelerCount = trip.nbTravelers;
    final innerRadius = AppRadius.cornerRadius24 - _borderWidth;

    return Container(
      decoration: const BoxDecoration(
        color: _frameColor,
        borderRadius: AppRadius.large24,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A0E1A2B),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(_borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppHaptics.light();
              TripHomeRoute(tripId: trip.id).push(context);
            },
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCover)
                    OptimizedImage.tripCover(
                      trip.coverImageUrl!,
                      errorWidget: const HomeTripHeroCoverFallback(),
                    )
                  else
                    const HomeTripHeroCoverFallback(),
                  const HomeTripHeroCoverScrim(),
                  Positioned(
                    top: AppSpacing.space16,
                    left: AppSpacing.space16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeTripHeroCountdownPill(label: _deadlineLabel(l10n)),
                        if (travelerCount != null && travelerCount > 0) ...[
                          const SizedBox(width: AppSpacing.space8),
                          HomeTripTravelersPill(
                            label: l10n.homeActiveTripTravelersAbbrev(
                              travelerCount,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.space16,
                    right: AppSpacing.space16,
                    child: CompletionRing(
                      percentage: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.space16,
                    right: AppSpacing.space16,
                    bottom: AppSpacing.space16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSerifDisplay,
                            fontSize: 30,
                            fontWeight: FontWeight.w400,
                            color: ColorName.surface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateRangeText.isNotEmpty)
                          Text(
                            dateRangeText,
                            style: TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ColorName.surface.withValues(alpha: 0.82),
                            ),
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
