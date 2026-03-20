import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/view/onboarding_home_view.dart';
import 'package:bagtrip/home/view/trip_manager_home_view.dart';
import 'package:bagtrip/home/widgets/shared_home_widgets.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, homeState) {
            if (homeState is HomeLoading || homeState is HomeInitial) {
              return const LoadingView();
            }

            if (homeState is HomeError) {
              return ErrorView(
                message: toUserFriendlyMessage(
                  homeState.error,
                  AppLocalizations.of(context)!,
                ),
                onRetry: () => context.read<HomeBloc>().add(LoadHome()),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(RefreshHome());
                for (final s in ['ongoing', 'planned', 'completed']) {
                  context.read<TripManagementBloc>().add(
                    LoadTripsByStatus(status: s),
                  );
                }
              },
              child: switch (homeState) {
                HomeNewUser() => OnboardingHomeView(state: homeState),
                HomeActiveTrip() => _ActiveTripHome(state: homeState),
                HomeTripManager() => TripManagerHomeView(state: homeState),
                _ => const LoadingView(),
              },
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active trip — ongoing trip hero + today's activities
// ---------------------------------------------------------------------------

class _ActiveTripHome extends StatelessWidget {
  final HomeActiveTrip state;

  const _ActiveTripHome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;
    final trip = state.activeTrip;
    final destination = trip.destinationName ?? trip.title ?? '';

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space24,
            ),
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

        // Active trip hero card
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space24,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => TripHomeRoute(tripId: trip.id).go(context),
                borderRadius: AppRadius.large16,
                child: Container(
                  width: double.infinity,
                  padding: AppSpacing.allEdgeInsetSpace24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ColorName.primary, ColorName.secondary],
                    ),
                    borderRadius: AppRadius.large16,
                    boxShadow: [
                      BoxShadow(
                        color: ColorName.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorName.surface.withValues(alpha: 0.25),
                          borderRadius: AppRadius.medium8,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.flight_takeoff_rounded,
                          color: ColorName.surface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              destination.isNotEmpty
                                  ? l10n.homeActiveTripTitle(destination)
                                  : destination,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: ColorName.surface,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space4),
                            Text(
                              l10n.homeActiveTripDay(
                                state.currentDay,
                                state.totalDays,
                              ),
                              style: TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 13,
                                color: ColorName.surface.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: ColorName.surface.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Today's activities section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space32,
            ),
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

        if (state.todayActivities.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space16),
              child: ElegantEmptyState(
                icon: Icons.event_note,
                title: l10n.homeNoActivitiesToday,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final activity = state.todayActivities[index];
              return _ActivityRow(activity: activity);
            }, childCount: state.todayActivities.length),
          ),

        // Plan trip CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space24,
            ),
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

class _ActivityRow extends StatelessWidget {
  final Activity activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
        right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
        top: AppSpacing.space8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: AppRadius.medium8,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            if (activity.startTime != null) ...[
              Text(
                activity.startTime!,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorName.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
            ],
            Expanded(
              child: Text(
                activity.title,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
