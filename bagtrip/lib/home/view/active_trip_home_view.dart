import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/helpers/home_highlight_activity.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/home/view/active_trip_programme_view.dart';
import 'package:bagtrip/home/widgets/create_trip_card.dart';
import 'package:bagtrip/home/widgets/home_trip_hero_chrome.dart';
import 'package:bagtrip/home/widgets/home_trip_list_card.dart';
import 'package:bagtrip/home/widgets/home_two_zone_layout.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/widgets/completion_ring.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActiveTripHomeView extends StatelessWidget {
  final HomeActiveTrip state;

  const ActiveTripHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upcomingTrips = state.upcomingTrips;

    return HomeTwoZoneLayout(
      includeTopSafeArea: true,
      greeting: _timeAwareGreeting(state.displayName, l10n),
      subtitle: _subtitleText(l10n, upcomingTrips.length),
      topChildren: [_ActiveTripHeroCard(state: state)],
      bottomChildren: [
        if (upcomingTrips.isNotEmpty) ...[
          HomeTripListSection(
            compactHeader: true,
            title: upcomingTrips.length == 1
                ? l10n.homeUpcomingTripsHeaderSingle
                : l10n.homeUpcomingTripsHeaderPlural,
            trips: upcomingTrips,
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
        const CreateTripCard(),
      ],
    );
  }

  String _timeAwareGreeting(String name, AppLocalizations l10n) {
    if (name.isEmpty) return l10n.homeWelcomeTitle;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning(name);
    if (hour < 18) return l10n.homeGreetingAfternoon(name);
    return l10n.homeGreetingEvening(name);
  }

  String _subtitleText(AppLocalizations l10n, int tripCount) {
    if (tripCount == 0) return l10n.homeSubtitleEmpty;
    if (tripCount == 1) return l10n.homeSubtitleOneTrip;
    return l10n.homeSubtitleTrips(tripCount);
  }
}

class _ActiveTripHeroCard extends StatelessWidget {
  static const Color _progressPanelColor = ColorName.surface;
  static const double _borderWidth = 1.5;

  final HomeActiveTrip state;

  const _ActiveTripHeroCard({required this.state});

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

  void _openProgramme(BuildContext context) {
    AppHaptics.light();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActiveTripProgrammeView(state: state),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trip = state.activeTrip;
    final destination =
        trip.destinationName ?? trip.title ?? l10n.myTripFallback;
    final progress = tripCompletion(trip).clamp(0, 100);
    final dateRange =
        '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}';
    final hasCover =
        trip.coverImageUrl != null && trip.coverImageUrl!.isNotEmpty;
    final highlight = resolveHomeHighlightActivity(state.allActivities);
    final travelerCount = trip.nbTravelers;

    final innerRadius = AppRadius.cornerRadius24 - _borderWidth;

    return Container(
      decoration: const BoxDecoration(
        color: _progressPanelColor,
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
            onTap: () => _openProgramme(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
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
                            HomeTripHeroEyebrowPill(
                              label: l10n.homeActiveTripEyebrow,
                            ),
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
                            ),
                            Text(
                              dateRange,
                              style: TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorName.surface.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(color: _progressPanelColor),
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: highlight != null
                      ? _HomeHighlightActivityRow(highlight: highlight)
                      : Text(
                          l10n.homeNoActivitiesToday,
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorName.textMutedLight,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHighlightActivityRow extends StatelessWidget {
  const _HomeHighlightActivityRow({required this.highlight});

  final HomeHighlightActivity highlight;

  String _badgeLabel(AppLocalizations l10n, BuildContext context) {
    if (highlight.isNow) return l10n.scheduleBadgeNow;
    if (highlight.isTomorrow) return l10n.activeHomeContextTomorrow;
    if (highlight.isToday) return l10n.scheduleBadgeNext;
    final date = highlight.activity.date;
    if (date == null) return l10n.scheduleBadgeNext;
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM', locale).format(date);
  }

  String? _metaLine(Activity activity) {
    final parts = <String>[];
    if (activity.startTime != null && activity.startTime!.isNotEmpty) {
      parts.add(activity.startTime!);
    }
    if (activity.location != null && activity.location!.isNotEmpty) {
      parts.add(activity.location!);
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activity = highlight.activity;
    final meta = _metaLine(activity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          decoration: const BoxDecoration(
            color: ColorName.secondaryLight,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            _badgeLabel(l10n, context),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ColorName.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          activity.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ColorName.primaryDark,
            height: 1.3,
          ),
        ),
        if (meta != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ColorName.textMutedLight,
            ),
          ),
        ],
      ],
    );
  }
}
