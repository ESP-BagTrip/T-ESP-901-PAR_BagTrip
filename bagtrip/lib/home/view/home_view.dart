import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/bloc/home_bloc.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
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

            if (homeState is! HomeLoaded) {
              return const LoadingView();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadHome());
                for (final s in ['ongoing', 'planned', 'completed']) {
                  context.read<TripManagementBloc>().add(
                    LoadTripsByStatus(status: s),
                  );
                }
              },
              child: homeState.isNewUser
                  ? _NewUserHome(state: homeState)
                  : _ReturningUserHome(state: homeState),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New user — immersive welcome, single CTA, no empty lists
// ---------------------------------------------------------------------------

class _NewUserHome extends StatelessWidget {
  final HomeLoaded state;

  const _NewUserHome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  MediaQuery.paddingOf(context).left + AppSpacing.space24,
            ),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Welcome icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ColorName.primary, ColorName.secondary],
                    ),
                    borderRadius: AppRadius.large24,
                    boxShadow: [
                      BoxShadow(
                        color: ColorName.primary.withValues(alpha: 0.3),
                        offset: const Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: ColorName.surface,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.space32),

                // Greeting
                Text(
                  name.isNotEmpty
                      ? l10n.homeGreeting(name)
                      : l10n.homeWelcomeTitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space8),

                // Subtitle
                Text(
                  l10n.homeWelcomeSubtitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space48),

                // Primary CTA — large
                _WelcomeCta(l10n: l10n),

                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCta extends StatelessWidget {
  final AppLocalizations l10n;

  const _WelcomeCta({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => const TripCreationRoute().go(context),
        borderRadius: AppRadius.large24,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primary, ColorName.secondary],
            ),
            borderRadius: AppRadius.large24,
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.35),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: ColorName.surface,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                l10n.homeCreateFirstTrip,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ColorName.surface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Returning user — next trip hero + CTA + trip list
// ---------------------------------------------------------------------------

class _ReturningUserHome extends StatelessWidget {
  final HomeLoaded state;

  const _ReturningUserHome({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = state.displayName;

    return CustomScrollView(
      slivers: [
        // Section A — Header
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

        // Section B — Next Trip Hero (conditional)
        if (state.hasNextTrip)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
                right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
                top: AppSpacing.space24,
              ),
              child: _NextTripHero(
                trip: state.nextTrip!,
                daysUntil: state.daysUntilNextTrip,
              ),
            ),
          ),

        // Section C — Plan a Trip CTA
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: MediaQuery.paddingOf(context).left + AppSpacing.space24,
              right: MediaQuery.paddingOf(context).right + AppSpacing.space24,
              top: AppSpacing.space24,
            ),
            child: _PlanTripCta(l10n: l10n),
          ),
        ),

        // Section D — My Trips
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.space8),
            child: _TripsSection(l10n: l10n),
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

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _NextTripHero extends StatelessWidget {
  final Trip trip;
  final int? daysUntil;

  const _NextTripHero({required this.trip, this.daysUntil});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = trip.destinationName ?? trip.title ?? '';
    final countdown = daysUntil != null
        ? l10n.nextTripCountdown(daysUntil!)
        : '';

    return Material(
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
                      displayName,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ColorName.surface,
                      ),
                    ),
                    if (countdown.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        countdown,
                        style: TextStyle(
                          fontFamily: FontFamily.b612,
                          fontSize: 13,
                          color: ColorName.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
    );
  }
}

class _PlanTripCta extends StatelessWidget {
  final AppLocalizations l10n;

  const _PlanTripCta({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => const TripCreationRoute().go(context),
        borderRadius: AppRadius.large16,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: 20,
          ),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: ColorName.primary.withValues(alpha: 0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ColorName.primary, ColorName.secondary],
                  ),
                  borderRadius: AppRadius.medium8,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  color: ColorName.surface,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.planTripCta,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.planTripCtaSubtitle,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  color: Colors.black.withValues(alpha: 0.06),
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

              return const SizedBox.shrink();
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
