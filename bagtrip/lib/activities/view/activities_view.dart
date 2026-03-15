import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/components/empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/personalization_colors.dart';
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
  final DateTime? tripStartDate;

  const ActivitiesView({
    super.key,
    required this.tripId,
    this.role = 'OWNER',
    this.isCompleted = false,
    this.tripStartDate,
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
              return const LoadingView();
            }
            if (state is ActivityError) {
              return ErrorView(
                message: toUserFriendlyMessage(
                  state.error,
                  AppLocalizations.of(context)!,
                ),
                onRetry: () => context.read<ActivityBloc>().add(
                  LoadActivities(tripId: tripId),
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

              final hasSuggested = activities.any(
                (a) => a.validationStatus == ValidationStatus.suggested,
              );

              return Column(
                children: [
                  if (hasSuggested)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: PersonalizationColors.accentBlue.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: PersonalizationColors.accentBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.activityDisclaimerSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: PersonalizationColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: PaginatedList<Activity>(
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
                      emptyWidget: EmptyState(
                        icon: Icons.event_outlined,
                        title: AppLocalizations.of(context)!.activitiesEmpty,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.activitiesEmptySubtitle,
                      ),
                      groupBy: _groupByDay,
                      sectionHeaderBuilder: (context, dateKey) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          DateFormat(
                            'EEEE d MMMM yyyy',
                          ).format(DateTime.parse(dateKey)),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      itemBuilder: (context, activity, _) => ActivityCard(
                        activity: activity,
                        isViewer: role == 'VIEWER' || isCompleted,
                        onEdit: () =>
                            _showForm(context, tripId, activity: activity),
                        onDelete: () => context.read<ActivityBloc>().add(
                          DeleteActivity(
                            tripId: tripId,
                            activityId: activity.id,
                          ),
                        ),
                        onValidate: () => _showValidateModal(context, activity),
                      ),
                    ),
                  ),
                ],
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
              final suggestedDay = s['suggestedDay'] as int?;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Row(
                    children: [
                      Flexible(child: Text(s['title'] ?? '')),
                      if (suggestedDay != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PersonalizationColors.accentBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Jour $suggestedDay',
                            style: const TextStyle(
                              fontSize: 10,
                              color: PersonalizationColors.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                      String activityDate;
                      if (suggestedDay != null && tripStartDate != null) {
                        activityDate = tripStartDate!
                            .add(Duration(days: suggestedDay - 1))
                            .toIso8601String()
                            .split('T')[0];
                      } else {
                        activityDate = DateTime.now().toIso8601String().split(
                          'T',
                        )[0];
                      }
                      context.read<ActivityBloc>().add(
                        AddSuggestedActivity(
                          tripId: tripId,
                          data: {
                            'title': s['title'] ?? '',
                            'description': s['description'],
                            'category': s['category'] ?? 'OTHER',
                            'estimatedCost': s['estimatedCost'],
                            'location': s['location'],
                            'date': activityDate,
                            'validationStatus': 'SUGGESTED',
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

  void _showValidateModal(BuildContext context, Activity activity) {
    final l10n = AppLocalizations.of(context)!;
    final costController = TextEditingController(
      text: activity.estimatedCost?.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.activityValidateConfirmTitle,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.activityValidateConfirmMessage,
              style: Theme.of(
                sheetContext,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.activityValidateCostLabel,
                border: const OutlineInputBorder(),
                prefixText: '\u20ac ',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final newCost = double.tryParse(costController.text);
                final data = <String, dynamic>{'validationStatus': 'VALIDATED'};
                if (newCost != null) {
                  data['estimatedCost'] = newCost;
                }
                context.read<ActivityBloc>().add(
                  UpdateActivity(
                    tripId: tripId,
                    activityId: activity.id,
                    data: data,
                  ),
                );
                Navigator.of(sheetContext).pop();
              },
              child: Text(l10n.activityValidateConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
