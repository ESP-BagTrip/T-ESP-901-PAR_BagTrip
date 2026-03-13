import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TripsListView extends StatelessWidget {
  const TripsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes voyages'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Planifiés'),
              Tab(text: 'Terminés'),
            ],
          ),
        ),
        body: BlocBuilder<TripManagementBloc, TripManagementState>(
          builder: (context, state) {
            if (state is TripManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TripManagementError) {
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
                    Text(state.message),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed:
                          () => context.read<TripManagementBloc>().add(
                            LoadTrips(),
                          ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            if (state is TripManagementLoaded) {
              final grouped = state.groupedTrips;
              return TabBarView(
                children: [
                  _TripListTab(
                    trips: grouped.ongoing,
                    emptyMessage: 'Aucun voyage en cours',
                    emptyIcon: Icons.flight_takeoff,
                  ),
                  _TripListTab(
                    trips: grouped.planned,
                    emptyMessage: 'Aucun voyage planifié',
                    emptyIcon: Icons.calendar_today,
                  ),
                  _TripListTab(
                    trips: grouped.completed,
                    emptyMessage: 'Aucun voyage terminé',
                    emptyIcon: Icons.check_circle_outline,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/trips/planifier'),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau voyage'),
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
