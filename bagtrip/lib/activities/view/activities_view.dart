import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/widgets/activity_card.dart';
import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActivitiesView extends StatelessWidget {
  final String tripId;

  const ActivitiesView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state is ActivityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActivityError) {
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
                        () => context.read<ActivityBloc>().add(
                          LoadActivities(tripId: tripId),
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ActivitiesLoaded) {
            if (state.activities.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 64,
                      color: AppColors.hint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activities yet',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: AppColors.hint),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add activities to plan your trip',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              );
            }
            final sortedKeys = state.groupedByDay.keys.toList()..sort();
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateKey = sortedKeys[index];
                final dayActivities = state.groupedByDay[dateKey]!;
                final dateLabel = DateFormat(
                  'EEEE d MMMM yyyy',
                ).format(DateTime.parse(dateKey));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...dayActivities.map(
                      (activity) => ActivityCard(
                        activity: activity,
                        onEdit:
                            () =>
                                _showForm(context, tripId, activity: activity),
                        onDelete:
                            () => context.read<ActivityBloc>().add(
                              DeleteActivity(
                                tripId: tripId,
                                activityId: activity.id,
                              ),
                            ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, tripId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, String tripId, {Activity? activity}) {
    final bloc = context.read<ActivityBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ActivityForm(
            tripId: tripId,
            activity: activity,
            onSave: (data) {
              if (activity != null) {
                bloc.add(
                  UpdateActivity(
                    tripId: tripId,
                    activityId: activity.id,
                    data: data,
                  ),
                );
              } else {
                bloc.add(CreateActivity(tripId: tripId, data: data));
              }
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
