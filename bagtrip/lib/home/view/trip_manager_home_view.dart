import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/home/widgets/completed_trips_carousel.dart';
import 'package:bagtrip/home/widgets/shared_home_widgets.dart';
import 'package:bagtrip/home/widgets/trip_manager_shimmer.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripManagerHomeView extends StatelessWidget {
  final HomeTripManager state;

  const TripManagerHomeView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;

    return CustomScrollView(
      slivers: [
        // A — Greeting header
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: 0,
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
        ),

        // B — NextTripHero (conditional)
        if (state.hasNextTrip)
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: 1,
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
                  right:
                      MediaQuery.paddingOf(context).right + AppSpacing.space24,
                  top: AppSpacing.space24,
                ),
                child: NextTripHero(
                  trip: state.nextTrip!,
                  daysUntil: state.daysUntilNextTrip,
                  completionPercent: state.nextTripCompletion,
                ),
              ),
            ),
          ),

        // C — PlanTripCta
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: 2,
            child: Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
                right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
                top: AppSpacing.space24,
              ),
              child: PlanTripCta(l10n: l10n),
            ),
          ),
        ),

        // D — "MY TRIPS" section header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space32,
            ),
            child: Text(
              l10n.tripsMyTrips.toUpperCase(),
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

        // E — Trips section (segment control + tab content)
        SliverToBoxAdapter(
          child: StaggeredFadeIn(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space8),
              child: _TripsSection(l10n: l10n),
            ),
          ),
        ),

        // F — Completed trips carousel (conditional)
        if (state.completedTrips.isNotEmpty)
          SliverToBoxAdapter(
            child: StaggeredFadeIn(
              index: 4,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space24),
                child: CompletedTripsCarousel(
                  completedTrips: state.completedTrips,
                ),
              ),
            ),
          ),

        // G — Bottom padding
        SliverToBoxAdapter(
          child: SizedBox(
            height: AdaptivePlatform.isIOS ? 100 : AppSpacing.space32,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets — moved from home_view.dart
// ---------------------------------------------------------------------------

class _TripsSection extends StatefulWidget {
  final AppLocalizations l10n;

  const _TripsSection({required this.l10n});

  @override
  State<_TripsSection> createState() => _TripsSectionState();
}

class _TripsSectionState extends State<_TripsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Segmented control
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          padding: AppSpacing.allEdgeInsetSpace4,
          decoration: BoxDecoration(
            color: isDark ? ColorName.surfaceDark : ColorName.surfaceLight,
            borderRadius: AppRadius.pill,
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.pill,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  offset: const Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.outline,
            labelStyle: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: l10n.tripStatusOngoing),
              Tab(text: l10n.tripStatusPlanned),
              Tab(text: l10n.tripStatusCompleted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space12),

        // Trip lists
        SizedBox(
          height: 300,
          child: BlocBuilder<TripManagementBloc, TripManagementState>(
            builder: (context, state) {
              if (state is TripsTabLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _TripListContent(
                      tabData: state.getTab('ongoing'),
                      status: 'ongoing',
                      emptyMessage: l10n.tripsEmptyOngoing,
                      emptyIcon: Icons.flight_takeoff,
                    ),
                    _TripListContent(
                      tabData: state.getTab('planned'),
                      status: 'planned',
                      emptyMessage: l10n.tripsEmptyPlanned,
                      emptyIcon: Icons.calendar_today,
                    ),
                    _TripListContent(
                      tabData: state.getTab('completed'),
                      status: 'completed',
                      emptyMessage: l10n.tripsEmptyCompleted,
                      emptyIcon: Icons.check_circle_outline,
                    ),
                  ],
                );
              }

              if (state is TripsLoaded) {
                final grouped = state.groupedTrips;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _LegacyTripList(
                      trips: grouped.ongoing,
                      emptyMessage: l10n.tripsEmptyOngoing,
                      emptyIcon: Icons.flight_takeoff,
                    ),
                    _LegacyTripList(
                      trips: grouped.planned,
                      emptyMessage: l10n.tripsEmptyPlanned,
                      emptyIcon: Icons.calendar_today,
                    ),
                    _LegacyTripList(
                      trips: grouped.completed,
                      emptyMessage: l10n.tripsEmptyCompleted,
                      emptyIcon: Icons.check_circle_outline,
                    ),
                  ],
                );
              }

              return const TripManagerShimmer();
            },
          ),
        ),
      ],
    );
  }
}

class _TripListContent extends StatelessWidget {
  final TripTabData tabData;
  final String status;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TripListContent({
    required this.tabData,
    required this.status,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return PaginatedList<Trip>(
      items: tabData.trips,
      hasMore: tabData.hasMore,
      isLoadingMore: tabData.isLoadingMore,
      onLoadMore: () => context.read<TripManagementBloc>().add(
        LoadMoreTripsByStatus(status: status),
      ),
      onRefresh: () async {
        context.read<TripManagementBloc>().add(
          LoadTripsByStatus(status: status),
        );
      },
      padding: AppSpacing.verticalSpace4,
      emptyWidget: ElegantEmptyState(icon: emptyIcon, title: emptyMessage),
      itemBuilder: (context, trip, _) => TripCard(
        trip: trip,
        onTap: () => TripHomeRoute(tripId: trip.id).go(context),
      ),
    );
  }
}

class _LegacyTripList extends StatelessWidget {
  final List<Trip> trips;
  final String emptyMessage;
  final IconData emptyIcon;

  const _LegacyTripList({
    required this.trips,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return ElegantEmptyState(icon: emptyIcon, title: emptyMessage);
    }
    return ListView.builder(
      padding: AppSpacing.verticalSpace4,
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return TripCard(
          trip: trip,
          onTap: () => TripHomeRoute(tripId: trip.id).go(context),
        );
      },
    );
  }
}
