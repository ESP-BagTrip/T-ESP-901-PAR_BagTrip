import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/home/view/active_trip_programme_view.dart';
import 'package:bagtrip/home/widgets/create_trip_card.dart';
import 'package:bagtrip/home/widgets/home_trip_list_card.dart';
import 'package:bagtrip/components/optimized_image.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ActiveTripHomeView extends StatelessWidget {
  final HomeActiveTrip state;

  const ActiveTripHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final upcomingTrips = state.upcomingTrips;

    return ColoredBox(
      color: const Color(0xFFF5F7FA),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space16,
          MediaQuery.paddingOf(context).top + AppSpacing.space16,
          AppSpacing.space16,
          MediaQuery.paddingOf(context).bottom + AppSpacing.space24,
        ),
        children: [
          Text(
            _timeAwareGreeting(state.displayName, l10n),
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1D2330),
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            _subtitleText(l10n, upcomingTrips.length),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 16,
              color: Color(0xFF6E7480),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          _ActiveTripHeroCard(state: state),
          const SizedBox(height: AppSpacing.space24),
          if (upcomingTrips.isNotEmpty)
            HomeTripListSection(
              title: upcomingTrips.length == 1
                  ? l10n.homeUpcomingTripsHeaderSingle
                  : l10n.homeUpcomingTripsHeaderPlural,
              trips: upcomingTrips,
            ),
          if (upcomingTrips.isNotEmpty)
            const SizedBox(height: AppSpacing.space8),
          const CreateTripCard(),
        ],
      ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.large24,
        onTap: () => _openProgramme(context),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: AppRadius.large24,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A0E1A2B),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.large24,
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
                          errorWidget: const _ActiveTripCoverFallback(),
                        )
                      else
                        const _ActiveTripCoverFallback(),
                      DecoratedBox(
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
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n.homeActiveTripEyebrow,
                              style: const TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: ColorName.secondary,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space8),
                            Text(
                              destination,
                              style: const TextStyle(
                                fontFamily: FontFamily.dMSerifDisplay,
                                fontSize: 44,
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
                  decoration: const BoxDecoration(color: ColorName.surface),
                  padding: const EdgeInsets.all(AppSpacing.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeTripProgressTitle,
                        style: const TextStyle(
                          fontFamily: FontFamily.dMSans,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ColorName.primaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadius.small4,
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                minHeight: 7,
                                backgroundColor: ColorName.primarySoftLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  ColorName.secondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Text(
                            l10n.homeTripProgressPercent(progress),
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ColorName.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _openProgramme(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorName.primaryDark,
                            foregroundColor: ColorName.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.pill,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space12,
                            ),
                          ),
                          child: Text(
                            l10n.homeResumeActiveTripCta,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
    );
  }
}

class _ActiveTripCoverFallback extends StatelessWidget {
  const _ActiveTripCoverFallback();

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
    );
  }
}
