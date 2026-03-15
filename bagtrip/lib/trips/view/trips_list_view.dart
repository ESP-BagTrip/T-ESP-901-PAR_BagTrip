import 'package:bagtrip/components/empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class TripsListView extends StatefulWidget {
  const TripsListView({super.key});

  @override
  State<TripsListView> createState() => _TripsListViewState();
}

class _TripsListViewState extends State<TripsListView> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<TripManagementBloc>();
    for (final status in ['ongoing', 'planned', 'completed']) {
      bloc.add(LoadTripsByStatus(status: status));
    }
    context.read<NotificationBloc>().add(LoadUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.tripsMyTrips),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is UnreadCountLoaded) {
                  unreadCount = state.count;
                } else if (state is NotificationsLoaded) {
                  unreadCount = state.unreadCount;
                }
                return IconButton(
                  onPressed: () => const NotificationsRoute().push(context),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: Icon(
                      AdaptivePlatform.isIOS
                          ? CupertinoIcons.bell
                          : Icons.notifications_outlined,
                    ),
                  ),
                );
              },
            ),
            if (AdaptivePlatform.isIOS)
              IconButton(
                onPressed: () => const PlanifierRoute().go(context),
                icon: const Icon(CupertinoIcons.add),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.tripStatusOngoing),
              Tab(text: AppLocalizations.of(context)!.tripStatusPlanned),
              Tab(text: AppLocalizations.of(context)!.tripStatusCompleted),
            ],
          ),
        ),
        body: BlocBuilder<TripManagementBloc, TripManagementState>(
          builder: (context, state) {
            if (state is TripsLoading) {
              return const LoadingView();
            }

            if (state is TripError) {
              return ErrorView(
                message: toUserFriendlyMessage(
                  state.error,
                  AppLocalizations.of(context)!,
                ),
                onRetry: () {
                  for (final s in ['ongoing', 'planned', 'completed']) {
                    context.read<TripManagementBloc>().add(
                      LoadTripsByStatus(status: s),
                    );
                  }
                },
              );
            }

            if (state is TripsTabLoaded) {
              return TabBarView(
                children: [
                  _TripListTab(
                    tabData: state.getTab('ongoing'),
                    status: 'ongoing',
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyOngoing,
                    emptyIcon: Icons.flight_takeoff,
                  ),
                  _TripListTab(
                    tabData: state.getTab('planned'),
                    status: 'planned',
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyPlanned,
                    emptyIcon: Icons.calendar_today,
                  ),
                  _TripListTab(
                    tabData: state.getTab('completed'),
                    status: 'completed',
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyCompleted,
                    emptyIcon: Icons.check_circle_outline,
                  ),
                ],
              );
            }

            // Backward compat with TripsLoaded (grouped)
            if (state is TripsLoaded) {
              final grouped = state.groupedTrips;
              return TabBarView(
                children: [
                  _LegacyTripListTab(
                    trips: grouped.ongoing,
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyOngoing,
                    emptyIcon: Icons.flight_takeoff,
                  ),
                  _LegacyTripListTab(
                    trips: grouped.planned,
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyPlanned,
                    emptyIcon: Icons.calendar_today,
                  ),
                  _LegacyTripListTab(
                    trips: grouped.completed,
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyCompleted,
                    emptyIcon: Icons.check_circle_outline,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: AdaptivePlatform.isIOS
            ? null
            : FloatingActionButton.extended(
                onPressed: () => const PlanifierRoute().go(context),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.tripsNewTrip),
              ),
      ),
    );
  }
}

class _TripListTab extends StatelessWidget {
  final TripTabData tabData;
  final String status;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TripListTab({
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      emptyWidget: EmptyState(icon: emptyIcon, title: emptyMessage),
      itemBuilder: (context, trip, _) => TripCard(
        trip: trip,
        onTap: () => TripHomeRoute(tripId: trip.id).push(context),
      ),
    );
  }
}

/// Legacy tab for backward compat with TripsLoaded (non-paginated).
class _LegacyTripListTab extends StatelessWidget {
  final List<Trip> trips;
  final String emptyMessage;
  final IconData emptyIcon;

  const _LegacyTripListTab({
    required this.trips,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return EmptyState(icon: emptyIcon, title: emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TripManagementBloc>().add(LoadTrips());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return TripCard(
            trip: trip,
            onTap: () => TripHomeRoute(tripId: trip.id).push(context),
          );
        },
      ),
    );
  }
}
