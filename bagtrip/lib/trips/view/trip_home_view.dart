import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
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
          if (state is TripManagementLoaded || state is TripDeleted) {
            context.go('/trips');
          }
          if (state is TripManagementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<TripManagementBloc>().add(
              LoadTripHome(tripId: tripId),
            );
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
            final isViewer = trip.role == 'VIEWER';
            final isCompleted = trip.status == TripStatus.completed;

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
                      if (!isViewer)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed:
                                () => context.go(
                                  '/trips/$tripId/shares',
                                  extra: trip.role,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.tripCompletedReadOnly,
                            ),
                          ),
                        ],
                      ),
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
                              (feature) => TripFeatureTileWidget(
                                feature: feature,
                                onTap:
                                    feature.enabled
                                        ? () => context.go(
                                          '/trips/$tripId/${feature.route}',
                                          extra: {
                                            'role': trip.role,
                                            'isCompleted': isCompleted,
                                          },
                                        )
                                        : null,
                              ),
                            )
                            .toList(),
                  ),
                ),
                if (trip.status == TripStatus.draft && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<TripManagementBloc>().add(
                            UpdateTripStatus(tripId: tripId, status: 'PLANNED'),
                          );
                        },
                        icon: const Icon(Icons.check_circle),
                        label: Text(AppLocalizations.of(context)!.markAsReady),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                if (trip.status == TripStatus.ongoing && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<TripManagementBloc>().add(
                            UpdateTripStatus(
                              tripId: tripId,
                              status: 'COMPLETED',
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
                if (isCompleted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/trips/$tripId/feedback'),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text('Donner un avis'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                if (trip.status == TripStatus.draft && !isViewer)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder:
                                (dialogContext) => AlertDialog(
                                  title: const Text('Supprimer le voyage'),
                                  content: const Text(
                                    'Êtes-vous sûr de vouloir supprimer ce voyage ? Cette action est irréversible.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(dialogContext).pop(),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        context.read<TripManagementBloc>().add(
                                          DeleteTrip(tripId: tripId),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                      child: const Text('Supprimer'),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer le voyage'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
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
