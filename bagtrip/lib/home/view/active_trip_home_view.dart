import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/helpers/today_activities.dart';
import 'package:bagtrip/home/widgets/active_trip_hero.dart';
import 'package:bagtrip/home/widgets/quick_actions_bar.dart';
import 'package:bagtrip/home/widgets/shared_home_widgets.dart';
import 'package:bagtrip/home/widgets/timeline_activity_row.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ActiveTripHomeView extends StatelessWidget {
  final HomeActiveTrip state;

  const ActiveTripHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;
    final trip = state.activeTrip;
    final result = classifyTodayActivities(allActivities: state.allActivities);
    final allTimeline = [...result.allDayActivities, ...result.timedActivities];
    final hPadding = EdgeInsets.only(
      left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
      right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
    );

    int fadeIndex = 0;

    return CustomScrollView(
      slivers: [
        // Greeting
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: hPadding.copyWith(top: AppSpacing.space24),
              child: Text(
                name.isNotEmpty
                    ? l10n.homeGreeting(name)
                    : l10n.planifierGreeting,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),

        // Hero card
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: hPadding.copyWith(top: AppSpacing.space24),
              child: ActiveTripHero(
                trip: trip,
                currentDay: state.currentDay,
                totalDays: state.totalDays,
                weatherSummary: state.weatherSummary,
              ),
            ),
          ),
        ),

        // Today's schedule header
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: fadeIndex++,
            child: Padding(
              padding: hPadding.copyWith(top: AppSpacing.space32),
              child: Text(
                l10n.homeTodayActivities.toUpperCase(),
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),

        // Timeline or empty state
        if (allTimeline.isEmpty)
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: fadeIndex++,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space16),
                child: ElegantEmptyState(
                  icon: Icons.event_note,
                  title: l10n.homeNoActivitiesToday,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final activity = allTimeline[index];
              final isNext = activity == result.nextActivity;
              final isLast = index == allTimeline.length - 1;
              return StaggeredFadeIn(
                index: fadeIndex + index,
                child: Padding(
                  padding: hPadding,
                  child: TimelineActivityRow(
                    activity: activity,
                    isNext: isNext,
                    isLast: isLast,
                  ),
                ),
              );
            }, childCount: allTimeline.length),
          ),

        // Tomorrow section
        if (result.tomorrowActivities.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final idx = fadeIndex + allTimeline.length;
                return StaggeredFadeIn(
                  index: idx,
                  child: Padding(
                    padding: hPadding.copyWith(top: AppSpacing.space32),
                    child: Row(
                      children: [
                        Text(
                          l10n.activeTripsTomorrow.toUpperCase(),
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Text(
                          l10n.activeTripsTomorrowCount(
                            result.tomorrowActivities.length,
                          ),
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final activity = result.tomorrowActivities[index];
                final idx = fadeIndex + allTimeline.length + 1 + index;
                return StaggeredFadeIn(
                  index: idx,
                  child: Padding(
                    padding: hPadding,
                    child: TimelineActivityRow(
                      activity: activity,
                      isLast:
                          index ==
                          (result.tomorrowActivities.length > 3
                              ? 2
                              : result.tomorrowActivities.length - 1),
                    ),
                  ),
                );
              },
              childCount: result.tomorrowActivities.length > 3
                  ? 3
                  : result.tomorrowActivities.length,
            ),
          ),
        ],

        // Quick actions
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              final tomorrowCount = result.tomorrowActivities.isNotEmpty
                  ? (result.tomorrowActivities.length > 3
                            ? 3
                            : result.tomorrowActivities.length) +
                        1
                  : 0;
              final idx =
                  fadeIndex +
                  allTimeline.length +
                  tomorrowCount +
                  (allTimeline.isEmpty ? 1 : 0);
              return StaggeredFadeIn(
                index: idx,
                child: Padding(
                  padding: hPadding.copyWith(top: AppSpacing.space32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activeTripsQuickActions.toUpperCase(),
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      QuickActionsBar(tripId: trip.id),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Plan trip CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: hPadding.copyWith(top: AppSpacing.space24),
            child: PlanTripCta(l10n: l10n),
          ),
        ),

        // Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(
            height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
          ),
        ),
      ],
    );
  }
}
