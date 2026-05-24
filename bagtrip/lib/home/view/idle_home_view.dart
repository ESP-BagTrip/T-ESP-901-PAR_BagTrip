import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/widgets/create_trip_card.dart';
import 'package:bagtrip/home/widgets/home_trip_list_card.dart';
import 'package:bagtrip/home/widgets/home_two_zone_layout.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IdleHomeView extends StatelessWidget {
  final HomeIdle state;

  const IdleHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trips = state.upcomingTrips;
    final hasTrips = trips.isNotEmpty;

    final topChildren = <Widget>[
      if (state.backgroundOngoingTrip != null) const _OngoingTripResumeBanner(),
    ];

    final bottomChildren = <Widget>[
      if (!hasTrips)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space48),
          child: CreateTripCard(
            isFirstTrip: state.isNewUser,
            subtitle: l10n.homeCreateFirstTripSubtitle,
          ),
        )
      else ...[
        HomeTripListSection(
          compactHeader: true,
          title: trips.length == 1
              ? l10n.homeUpcomingTripsHeaderSingle
              : l10n.homeUpcomingTripsHeaderPlural,
          trips: trips,
        ),
        const SizedBox(height: AppSpacing.space8),
        CreateTripCard(isFirstTrip: state.isNewUser),
      ],
    ];

    return HomeTwoZoneLayout(
      includeTopSafeArea: true,
      greeting: _timeAwareGreeting(state.displayName, l10n),
      subtitle: _subtitleText(l10n, trips.length),
      topChildren: topChildren,
      bottomChildren: bottomChildren,
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

class _OngoingTripResumeBanner extends StatelessWidget {
  const _OngoingTripResumeBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<HomeBloc>().add(ResumeActiveTripHome());
        },
        borderRadius: AppRadius.large16,
        child: Ink(
          decoration: BoxDecoration(
            color: ColorName.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: ColorName.surface),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140E1A2B),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space12,
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Text(
                    l10n.homeResumeActiveTripSubtitle,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
