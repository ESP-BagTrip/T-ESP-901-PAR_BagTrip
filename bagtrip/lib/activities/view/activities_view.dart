import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/components/adaptive/adaptive_indicator.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bagtrip/activities/widgets/activity_card.dart';
import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActivitiesView extends StatelessWidget {
  final String tripId;
  final String role;
  final bool isCompleted;

  const ActivitiesView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final canEdit = role != 'VIEWER' && !isCompleted;

    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state is ActivityQuotaExceeded) {
          PremiumPaywall.show(context);
        } else if (state is ActivitySuggestionsLoaded) {
          _showSuggestionsSheet(context, state.suggestions);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.activitiesTitle),
          actions: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: AppLocalizations.of(
                  context,
                )!.activitiesSuggestionsTitle,
                onPressed: () {
                  context.read<ActivityBloc>().add(
                    SuggestActivities(tripId: tripId),
                  );
                },
              ),
            if (canEdit && AdaptivePlatform.isIOS)
              IconButton(
                icon: const Icon(CupertinoIcons.add),
                onPressed: () => _showForm(context, tripId),
              ),
          ],
        ),
        body: BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state is ActivityLoading ||
                state is ActivitySuggestionsLoading) {
              return const Center(child: AdaptiveIndicator());
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
                    Text(
                      toUserFriendlyMessage(
                        state.error,
                        AppLocalizations.of(context)!,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.read<ActivityBloc>().add(
                        LoadActivities(tripId: tripId),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retryButton),
                    ),
                  ],
                ),
              );
            }
            if (state is ActivitiesLoaded ||
                state is ActivitySuggestionsLoaded) {
              final activities = state is ActivitiesLoaded
                  ? state.activities
                  : (state as ActivitySuggestionsLoaded).activities;
              final hasMore = state is ActivitiesLoaded
                  ? state.hasMore
                  : (state as ActivitySuggestionsLoaded).hasMore;
              final isLoadingMore = state is ActivitiesLoaded
                  ? state.isLoadingMore
                  : (state as ActivitySuggestionsLoaded).isLoadingMore;

              return PaginatedList<Activity>(
                items: activities,
                hasMore: hasMore,
                isLoadingMore: isLoadingMore,
                onLoadMore: () => context.read<ActivityBloc>().add(
                  LoadMoreActivities(tripId: tripId),
                ),
                onRefresh: () async {
                  context.read<ActivityBloc>().add(
                    LoadActivities(tripId: tripId),
                  );
                },
                padding: const EdgeInsets.all(16),
                emptyWidget: Center(
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
                        AppLocalizations.of(context)!.activitiesEmpty,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.hint),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.activitiesEmptySubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                groupBy: _groupByDay,
                sectionHeaderBuilder: (context, dateKey) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    DateFormat(
                      'EEEE d MMMM yyyy',
                    ).format(DateTime.parse(dateKey)),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context, activity, _) => ActivityCard(
                  activity: activity,
                  isViewer: role == 'VIEWER' || isCompleted,
                  onEdit: () => _showForm(context, tripId, activity: activity),
                  onDelete: () => context.read<ActivityBloc>().add(
                    DeleteActivity(tripId: tripId, activityId: activity.id),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: canEdit && !AdaptivePlatform.isIOS
            ? FloatingActionButton(
                onPressed: () => _showForm(context, tripId),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  Map<String, List<Activity>> _groupByDay(List<Activity> activities) {
    final Map<String, List<Activity>> grouped = {};
    for (final activity in activities) {
      final key = DateFormat('yyyy-MM-dd').format(activity.date);
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    return grouped;
  }

  void _showSuggestionsSheet(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
  ) {
    if (AdaptivePlatform.isIOS) {
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => _buildSuggestionsContent(context, suggestions, ctx),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (sheetContext, scrollController) =>
              _buildSuggestionsListView(
                context,
                suggestions,
                sheetContext,
                scrollController,
              ),
        ),
      );
    }
  }

  Widget _buildSuggestionsContent(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
    BuildContext sheetContext,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: _buildSuggestionsListView(
        context,
        suggestions,
        sheetContext,
        null,
      ),
    );
  }

  Widget _buildSuggestionsListView(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
    BuildContext sheetContext,
    ScrollController? scrollController,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.activitiesSuggestionsTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (_, index) {
              final s = suggestions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(s['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s['description'] != null)
                        Text(
                          s['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (s['category'] != null)
                            Chip(
                              label: Text(
                                s['category'],
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          if (s['estimatedCost'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '~${s['estimatedCost']}€',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.hint),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      context.read<ActivityBloc>().add(
                        AddSuggestedActivity(
                          tripId: tripId,
                          data: {
                            'title': s['title'] ?? '',
                            'description': s['description'],
                            'category': s['category'] ?? 'OTHER',
                            'estimatedCost': s['estimatedCost'],
                            'location': s['location'],
                            'date': DateTime.now().toIso8601String().split(
                              'T',
                            )[0],
                          },
                        ),
                      );
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showForm(BuildContext context, String tripId, {Activity? activity}) {
    final bloc = context.read<ActivityBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ActivityForm(
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
