import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_feature_tile.dart';
import 'package:bagtrip/trips/widgets/trip_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TripHomeView extends StatelessWidget {
  final String tripId;

  const TripHomeView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TripManagementBloc, TripManagementState>(
        listener: (context, state) {
          if (state is TripManagementLoaded) {
            context.go('/trips');
          }
        },
        builder: (context, state) {
          if (state is TripHomeLoading) {
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
                          LoadTripHome(tripId: tripId),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is TripHomeLoaded) {
            final tripHome = state.tripHome;
            final trip = tripHome.trip;
            final stats = tripHome.stats;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      TripHeader(
                        trip: trip,
                        daysUntilTrip: stats.daysUntilTrip,
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          icon: Icons.people,
                          value: '${stats.nbTravelers}',
                          label: 'Voyageurs',
                        ),
                        if (stats.daysUntilTrip != null)
                          _StatItem(
                            icon: Icons.timer,
                            value: '${stats.daysUntilTrip}',
                            label: 'Jours restants',
                          ),
                        if (stats.tripDuration != null)
                          _StatItem(
                            icon: Icons.date_range,
                            value: '${stats.tripDuration}',
                            label: 'Jours de voyage',
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.3,
                    children:
                        tripHome.features
                            .map(
                              (feature) =>
                                  TripFeatureTileWidget(feature: feature),
                            )
                            .toList(),
                  ),
                ),
                if (trip.status.name == 'active')
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<TripManagementBloc>().add(
                            UpdateTripStatus(
                              tripId: tripId,
                              status: 'completed',
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Terminer le voyage'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
