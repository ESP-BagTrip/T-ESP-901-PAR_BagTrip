import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/notifications/bloc/notification_bloc.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TripsListView extends StatelessWidget {
  const TripsListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Load unread count for badge
    context.read<NotificationBloc>().add(LoadUnreadCount());

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
                  onPressed: () => context.push('/notifications'),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                );
              },
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
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TripError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      toUserFriendlyMessage(
                        state.error,
                        AppLocalizations.of(context)!,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<TripManagementBloc>().add(LoadTrips()),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retryButton),
                    ),
                  ],
                ),
              );
            }

            if (state is TripsLoaded) {
              final grouped = state.groupedTrips;
              return TabBarView(
                children: [
                  _TripListTab(
                    trips: grouped.ongoing,
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyOngoing,
                    emptyIcon: Icons.flight_takeoff,
                  ),
                  _TripListTab(
                    trips: grouped.planned,
                    emptyMessage: AppLocalizations.of(
                      context,
                    )!.tripsEmptyPlanned,
                    emptyIcon: Icons.calendar_today,
                  ),
                  _TripListTab(
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/planifier'),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context)!.tripsNewTrip),
        ),
      ),
    );
  }
}

class _TripListTab extends StatelessWidget {
  final List<Trip> trips;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TripListTab({
    required this.trips,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
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
            onTap: () => context.push('/trips/${trip.id}'),
          );
        },
      ),
    );
  }
}
