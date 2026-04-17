import 'package:bagtrip/activities/bloc/activity_bloc.dart';
import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_dialog.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/components/error_view.dart';
import 'package:bagtrip/components/loading_view.dart';
import 'package:bagtrip/components/paginated_list.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/premium_paywall.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/hero_nav_button.dart';
import 'package:bagtrip/design/widgets/review/panel_footer_cta.dart';
import 'package:bagtrip/design/widgets/review/pill_cta_button.dart';
import 'package:bagtrip/design/widgets/review/sheets/ai_suggestions_sheet.dart';
import 'package:bagtrip/design/widgets/review/sub_page_hero.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class ActivitiesView extends StatefulWidget {
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
  State<ActivitiesView> createState() => _ActivitiesViewState();
}

class _ActivitiesViewState extends State<ActivitiesView>
    with TickerProviderStateMixin {
  late final PanelFooterCtaController _footerController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _footerController = PanelFooterCtaController(vsync: this);
    _footerController.show();
  }

  @override
  void dispose() {
    _footerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _canEdit => widget.role != 'VIEWER' && !widget.isCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MultiBlocListener(
      listeners: [
        BlocListener<ActivityBloc, ActivityState>(
          listener: (context, state) {
            if (state is ActivityQuotaExceeded) {
              PremiumPaywall.show(context);
            } else if (state is ActivitySuggestionsLoaded) {
              _showSuggestionsSheet(context, state.suggestions);
            } else if (state is ActivitiesLoaded) {
              // Keep the shared TripDetailBloc list in sync with the
              // paginated subpage list so the panel reflects mutations
              // without a full trip refresh.
              context.read<TripDetailBloc>().add(RefreshTripDetail());
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: ColorName.surfaceVariant,
        body: Column(
          children: [
            SubPageHero(
              title: l10n.activitiesTitle,
              trailing: _canEdit
                  ? [
                      HeroNavButton(
                        icon: Icons.auto_awesome_rounded,
                        tooltip: l10n.activitiesSuggestionsTitle,
                        onPressed: () {
                          AppHaptics.light();
                          context.read<ActivityBloc>().add(
                            SuggestActivities(tripId: widget.tripId),
                          );
                        },
                      ),
                    ]
                  : null,
            ),
            Expanded(
              child: BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  if (state is ActivityLoading ||
                      state is ActivitySuggestionsLoading) {
                    return const LoadingView();
                  }
                  if (state is ActivityError) {
                    return ErrorView(
                      message: toUserFriendlyMessage(state.error, l10n),
                      onRetry: () => context.read<ActivityBloc>().add(
                        LoadActivities(tripId: widget.tripId),
                      ),
                    );
                  }
                  final activities = switch (state) {
                    ActivitiesLoaded() => state.activities,
                    ActivitySuggestionsLoaded() => state.activities,
                    _ => const <Activity>[],
                  };
                  final hasMore = switch (state) {
                    ActivitiesLoaded() => state.hasMore,
                    ActivitySuggestionsLoaded() => state.hasMore,
                    _ => false,
                  };
                  final isLoadingMore = switch (state) {
                    ActivitiesLoaded() => state.isLoadingMore,
                    ActivitySuggestionsLoaded() => state.isLoadingMore,
                    _ => false,
                  };
                  final hasSuggested = activities.any(
                    (a) => a.validationStatus == ValidationStatus.suggested,
                  );

                  return Column(
                    children: [
                      if (hasSuggested) _SuggestedBanner(l10n: l10n),
                      Expanded(
                        child: PaginatedList<Activity>(
                          items: activities,
                          hasMore: hasMore,
                          isLoadingMore: isLoadingMore,
                          onLoadMore: () => context.read<ActivityBloc>().add(
                            LoadMoreActivities(tripId: widget.tripId),
                          ),
                          onRefresh: () async {
                            context.read<ActivityBloc>().add(
                              LoadActivities(tripId: widget.tripId),
                            );
                          },
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.space16,
                            AppSpacing.space16,
                            AppSpacing.space16,
                            AppSpacing.space32 + 72,
                          ),
                          emptyWidget: _canEdit
                              ? ElegantEmptyState(
                                  icon: Icons.event_outlined,
                                  title: l10n.emptyActivitiesTitle,
                                  subtitle: l10n.emptyActivitiesSubtitle,
                                )
                              : ElegantEmptyState(
                                  icon: Icons.event_outlined,
                                  title: l10n.emptyActivitiesTitle,
                                ),
                          groupBy: _groupByDay,
                          sectionHeaderBuilder: (context, dateKey) => Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.space16,
                              bottom: AppSpacing.space12,
                            ),
                            child: Text(
                              DateFormat(
                                'EEEE d MMMM yyyy',
                              ).format(DateTime.parse(dateKey)).toUpperCase(),
                              style: const TextStyle(
                                fontFamily: FontFamily.dMSans,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: ColorName.hint,
                              ),
                            ),
                          ),
                          itemBuilder: (context, activity, _) => _ActivityRow(
                            activity: activity,
                            canEdit: _canEdit,
                            onEdit: () => _showForm(
                              context,
                              widget.tripId,
                              activity: activity,
                            ),
                            onDelete: () =>
                                _confirmDelete(context, activity, l10n),
                            onValidate: () =>
                                _showValidateModal(context, activity),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _canEdit
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space16,
                    AppSpacing.space8,
                    AppSpacing.space16,
                    AppSpacing.space16,
                  ),
                  child: PanelFooterCta(
                    controller: _footerController,
                    child: PillCtaButton(
                      label: l10n.addActivity,
                      leadingIcon: Icons.add_rounded,
                      onTap: () => _showForm(context, widget.tripId),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Map<String, List<Activity>> _groupByDay(List<Activity> activities) {
    final grouped = <String, List<Activity>>{};
    for (final activity in activities) {
      final key = DateFormat('yyyy-MM-dd').format(activity.date);
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    return grouped;
  }

  void _confirmDelete(
    BuildContext context,
    Activity activity,
    AppLocalizations l10n,
  ) {
    showAdaptiveAlertDialog(
      context: context,
      title: l10n.activityDeleteTitle,
      content: l10n.activityDeleteConfirm,
      confirmLabel: l10n.deleteButton,
      cancelLabel: l10n.cancelButton,
      isDestructive: true,
      onConfirm: () {
        AppHaptics.medium();
        context.read<ActivityBloc>().add(
          DeleteActivity(tripId: widget.tripId, activityId: activity.id),
        );
      },
    );
  }

  void _showSuggestionsSheet(
    BuildContext context,
    List<Map<String, dynamic>> suggestions,
  ) {
    final bloc = context.read<ActivityBloc>();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiSuggestionsSheet<Map<String, dynamic>>(
        title: l10n.activitiesSuggestionsTitle,
        subtitle: l10n.activitiesTitle,
        suggestions: suggestions,
        emptyTitle: l10n.emptyActivitiesTitle,
        emptySubtitle: l10n.activityDisclaimerSubtitle,
        disclaimer: l10n.activityDisclaimerSubtitle,
        itemBuilder: (sheetContext, s, _) => _SuggestionCard(
          suggestion: s,
          onAccept: () {
            final suggestedDay = s['suggestedDay'] as int?;
            final String activityDate;
            if (suggestedDay != null && widget.tripStartDate != null) {
              activityDate = widget.tripStartDate!
                  .add(Duration(days: suggestedDay - 1))
                  .toIso8601String()
                  .split('T')[0];
            } else {
              activityDate = DateTime.now().toIso8601String().split('T')[0];
            }
            bloc.add(
              AddSuggestedActivity(
                tripId: widget.tripId,
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
  }

  void _showForm(BuildContext context, String tripId, {Activity? activity}) {
    final bloc = context.read<ActivityBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.cornerRadius24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.space12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorName.hint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
                ),
                child: ActivityForm(
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
                    Navigator.of(sheetCtx).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValidateModal(BuildContext context, Activity activity) {
    final l10n = AppLocalizations.of(context)!;
    final costController = TextEditingController(
      text: activity.estimatedCost?.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.cornerRadius24),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.space24,
            right: AppSpacing.space24,
            top: AppSpacing.space24,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom +
                AppSpacing.space24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.activityValidateConfirmTitle,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 20,
                  color: ColorName.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                l10n.activityValidateConfirmMessage,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 13,
                  color: ColorName.hint,
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
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
              const SizedBox(height: AppSpacing.space24),
              PillCtaButton(
                label: l10n.activityValidateConfirm,
                onTap: () {
                  final newCost = double.tryParse(costController.text);
                  final data = <String, dynamic>{
                    'validationStatus': 'VALIDATED',
                  };
                  if (newCost != null) {
                    data['estimatedCost'] = newCost;
                  }
                  context.read<ActivityBloc>().add(
                    UpdateActivity(
                      tripId: widget.tripId,
                      activityId: activity.id,
                      data: data,
                    ),
                  );
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedBanner extends StatelessWidget {
  const _SuggestedBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        AppSpacing.space4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space12,
      ),
      decoration: BoxDecoration(
        color: ColorName.secondary.withValues(alpha: 0.08),
        borderRadius: AppRadius.large16,
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: ColorName.secondary),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              l10n.activityDisclaimerSubtitle,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                color: ColorName.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onValidate,
  });

  final Activity activity;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    final tile = ActivityTile(
      title: activity.title,
      description: activity.description ?? '',
      category: activity.category.name,
      onTap: canEdit
          ? () {
              if (activity.validationStatus == ValidationStatus.suggested) {
                onValidate();
              } else {
                onEdit();
              }
            }
          : null,
    );
    if (!canEdit) return tile;
    return Dismissible(
      key: ValueKey('activity-${activity.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        decoration: BoxDecoration(
          color: ColorName.error.withValues(alpha: 0.9),
          borderRadius: AppRadius.large16,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.space16),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: tile,
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onAccept});

  final Map<String, dynamic> suggestion;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    final suggestedDay = s['suggestedDay'] as int?;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: ColorName.surface,
        borderRadius: AppRadius.large16,
        border: Border.all(color: ColorName.primarySoftLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s['title'] as String? ?? '',
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 16,
                    color: ColorName.primaryDark,
                  ),
                ),
              ),
              if (suggestedDay != null) ...[
                const SizedBox(width: AppSpacing.space8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorName.secondary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'D$suggestedDay',
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ColorName.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (s['description'] != null) ...[
            const SizedBox(height: AppSpacing.space8),
            Text(
              s['description'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                color: ColorName.hint,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space12),
          Align(
            alignment: Alignment.centerRight,
            child: PillCtaButton(
              label: AppLocalizations.of(context)!.addActivity,
              leadingIcon: Icons.add_rounded,
              onTap: onAccept,
            ),
          ),
        ],
      ),
    );
  }
}
