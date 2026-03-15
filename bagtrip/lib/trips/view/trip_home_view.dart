import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/app_snackbar.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:bagtrip/trips/widgets/trip_feature_tile.dart';
import 'package:bagtrip/trips/widgets/trip_header.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/navigation/route_definitions.dart';

class TripHomeView extends StatelessWidget {
  final String tripId;

  const TripHomeView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TripManagementBloc, TripManagementState>(
        listener: (context, state) {
          if (state is TripsLoaded || state is TripDeleted) {
            const HomeRoute().go(context);
          }
          if (state is TripError) {
            AppSnackBar.showError(
              context,
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
            );
            context.read<TripManagementBloc>().add(
              LoadTripHome(tripId: tripId),
            );
          }
        },
        builder: (context, state) {
          if (state is TripHomeLoading) {
            return const LoadingView();
          }

          if (state is TripError) {
            return ErrorView(
              message: toUserFriendlyMessage(
                state.error,
                AppLocalizations.of(context)!,
              ),
              onRetry: () => context.read<TripManagementBloc>().add(
                LoadTripHome(tripId: tripId),
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
                          icon: Icon(
                            AdaptivePlatform.isIOS
                                ? CupertinoIcons.back
                                : Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => const HomeRoute().go(context),
                        ),
                      ),
                      if (!isViewer)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(
                              AdaptivePlatform.isIOS
                                  ? CupertinoIcons.share
                                  : Icons.share,
                              color: Colors.white,
                            ),
                            onPressed: () => SharesRoute(
                              tripId: tripId,
                              role: trip.role ?? 'OWNER',
                            ).go(context),
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
                          label: AppLocalizations.of(context)!.tripTravelers,
                        ),
                        if (stats.daysUntilTrip != null)
                          _StatItem(
                            icon: Icons.timer,
                            value: '${stats.daysUntilTrip}',
                            label: AppLocalizations.of(
                              context,
                            )!.tripDaysRemaining,
                          ),
                        if (stats.tripDuration != null)
                          _StatItem(
                            icon: Icons.date_range,
                            value: '${stats.tripDuration}',
                            label: AppLocalizations.of(context)!.tripTravelDays,
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
                    children: tripHome.features
                        .map(
                          (feature) => TripFeatureTileWidget(
                            feature: feature,
                            onTap: feature.enabled
                                ? () => tripFeatureRoute(
                                    tripId: tripId,
                                    featureRoute: feature.route,
                                    role: trip.role ?? 'OWNER',
                                    isCompleted: isCompleted,
                                  ).go(context)
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
                        label: Text(AppLocalizations.of(context)!.tripComplete),
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
                        onPressed: () =>
                            FeedbackRoute(tripId: tripId).go(context),
                        icon: const Icon(Icons.rate_review_outlined),
                        label: Text(
                          AppLocalizations.of(context)!.tripGiveReview,
                        ),
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
                          showAdaptiveAlertDialog(
                            context: context,
                            title: AppLocalizations.of(
                              context,
                            )!.tripDeleteTitle,
                            content: AppLocalizations.of(
                              context,
                            )!.tripDeleteConfirm,
                            confirmLabel: AppLocalizations.of(
                              context,
                            )!.deleteButton,
                            cancelLabel: AppLocalizations.of(
                              context,
                            )!.cancelButton,
                            isDestructive: true,
                            onConfirm: () {
                              context.read<TripManagementBloc>().add(
                                DeleteTrip(tripId: tripId),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          AppLocalizations.of(context)!.tripDeleteTitle,
                        ),
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
