import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/activities_view_cubit.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_view_mode.dart';
import 'package:bagtrip/trip_detail/view/panels/activities_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Activities tab — day selector on top + activities for the selected day.
///
/// Tapping an activity opens a [QuickPreviewSheet] with Validate (for
/// suggestions) / Edit / Delete actions — navigation to the full
/// activities page only happens if the user explicitly taps "See all
/// activities" inside that sheet or the footer. Swipe-to-delete and
/// long-press context menu bring the same actions to hand without modals.
class ActivitiesPanel extends StatelessWidget {
  const ActivitiesPanel({
    super.key,
    required this.tripId,
    required this.tripStartDate,
    required this.activities,
    required this.totalDays,
    required this.selectedDayIndex,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final DateTime? tripStartDate;
  final List<Activity> activities;
  final int totalDays;
  final int selectedDayIndex;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  int get _safeTotal => totalDays > 0 ? totalDays : 1;

  int get _safeIndex => selectedDayIndex.clamp(0, _safeTotal - 1);

  Iterable<DateTime> get _scheduledDates =>
      activities.map((a) => a.date).whereType<DateTime>();

  DateTime _dayDateFor(int index) {
    if (tripStartDate != null) {
      return tripStartDate!.add(Duration(days: index));
    }
    final scheduled = _scheduledDates;
    if (scheduled.isEmpty) return DateTime.now().add(Duration(days: index));
    final earliest = scheduled.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(
      earliest.year,
      earliest.month,
      earliest.day,
    ).add(Duration(days: index));
  }

  int _dayIndexFor(Activity activity) {
    final ad = activity.date;
    if (ad == null) return -1;
    final scheduled = _scheduledDates;
    if (scheduled.isEmpty) return 0;
    final earliest = scheduled.reduce((a, b) => a.isBefore(b) ? a : b);
    final base = DateTime(earliest.year, earliest.month, earliest.day);
    final current = DateTime(ad.year, ad.month, ad.day);
    return current.difference(base).inDays.clamp(0, _safeTotal - 1);
  }

  /// Returns ``(daily, unscheduled)``: ``daily[i]`` is the list of
  /// activities scheduled for day i, and ``unscheduled`` collects the
  /// activities the AI persisted without a calendar date (recurring
  /// dinners, free-form suggestions). The latter are surfaced in a
  /// dedicated bucket below the day selector so they never get dropped.
  ///
  /// Phase C3: ``source`` is the *filtered* list. The day-index basis
  /// still comes from the full trip activities so J1/J2 stay anchored
  /// to the trip's earliest activity instead of jumping around as the
  /// user toggles filters.
  ({List<List<Activity>> daily, List<Activity> unscheduled}) _groupByDayFor(
    List<Activity> source,
  ) {
    final scheduledSorted = source.where((a) => a.date != null).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    final unscheduled = source.where((a) => a.date == null).toList();
    final daily = List<List<Activity>>.generate(_safeTotal, (_) => []);
    for (final activity in scheduledSorted) {
      final idx = _dayIndexFor(activity);
      if (idx >= 0 && idx < daily.length) daily[idx].add(activity);
    }
    return (daily: daily, unscheduled: unscheduled);
  }

  String _categoryLabel(ActivityCategory category) => switch (category) {
    ActivityCategory.culture => 'CULTURE',
    ActivityCategory.nature => 'NATURE',
    ActivityCategory.food => 'FOOD',
    ActivityCategory.sport => 'SPORT',
    ActivityCategory.shopping => 'SHOP',
    ActivityCategory.nightlife => 'NIGHT',
    ActivityCategory.relaxation => 'RELAX',
    ActivityCategory.transport => 'TRANSPORT',
    ActivityCategory.other => 'ACT',
  };

  Future<void> _showAddSheet(BuildContext context) async {
    final bloc = context.read<TripDetailBloc>();
    final initialDate = _dayDateFor(_safeIndex);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityForm(
        tripId: tripId,
        initialDate: initialDate,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(CreateActivityFromDetail(data: data));
        },
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, Activity activity) async {
    final bloc = context.read<TripDetailBloc>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityForm(
        tripId: tripId,
        activity: activity,
        onSave: (data) {
          AppHaptics.medium();
          bloc.add(
            UpdateActivityFromDetail(activityId: activity.id, data: data),
          );
        },
      ),
    );
  }

  void _validate(BuildContext context, Activity activity) {
    AppHaptics.success();
    context.read<TripDetailBloc>().add(
      ValidateActivity(activityId: activity.id),
    );
  }

  void _delete(BuildContext context, Activity activity) {
    AppHaptics.medium();
    context.read<TripDetailBloc>().add(RejectActivity(activityId: activity.id));
  }

  Future<void> _showPreview(BuildContext context, Activity activity) async {
    final l10n = AppLocalizations.of(context)!;
    AppHaptics.light();
    final isSuggested = activity.validationStatus == ValidationStatus.suggested;
    await showQuickPreviewSheet(
      context: context,
      icon: Icons.event_note_rounded,
      title: activity.title,
      subtitle: _categoryLabel(activity.category),
      body: _ActivityPreviewBody(activity: activity),
      primaryAction: isSuggested && canEdit
          ? QuickPreviewAction(
              label: l10n.activityValidateAction,
              icon: Icons.check_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _validate(context, activity);
              },
            )
          : QuickPreviewAction(
              label: l10n.panelActionEdit,
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _showEditSheet(context, activity);
              },
            ),
      secondaryAction: isSuggested && canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionEdit,
              icon: Icons.edit_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _showEditSheet(context, activity);
              },
            )
          : null,
      destructiveAction: canEdit
          ? QuickPreviewAction(
              label: l10n.panelActionDelete,
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.of(context).pop();
                _delete(context, activity);
              },
              isDestructive: true,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.hiking_rounded,
          title: l10n.emptyActivitiesTitle,
          subtitle: canEdit ? l10n.emptyActivitiesSubtitle : null,
          ctaLabel: canEdit ? l10n.panelQuickAddActivity : null,
          onCta: canEdit ? () => _showAddSheet(context) : null,
        ),
      );
    }

    return BlocProvider<ActivitiesViewCubit>(
      create: (_) => ActivitiesViewCubit(),
      child: BlocBuilder<ActivitiesViewCubit, ActivitiesViewState>(
        builder: (context, viewState) {
          final filtered = viewState.applyTo(activities);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space56 + AppSpacing.space40,
                ),
                physics: const BouncingScrollPhysics(),
                children: [
                  _ViewModePicker(
                    selected: viewState.mode,
                    onChanged: (next) {
                      AppHaptics.light();
                      context.read<ActivitiesViewCubit>().setMode(next);
                    },
                  ),
                  const SizedBox(height: AppSpacing.space12),
                  _FilterBar(
                    state: viewState,
                    onValidationChanged: (next) {
                      AppHaptics.light();
                      context.read<ActivitiesViewCubit>().setValidationFilter(
                        next,
                      );
                    },
                    onCategoriesPressed: () => _showCategoryFilterSheet(
                      context,
                      viewState.categoryFilters,
                    ),
                    onClearFilters: () {
                      AppHaptics.medium();
                      context.read<ActivitiesViewCubit>().clearFilters();
                    },
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  if (filtered.isEmpty && viewState.hasActiveFilters)
                    _FilterEmptyState(l10n: l10n)
                  else
                    ..._buildModeChildren(
                      context,
                      l10n,
                      viewState.mode,
                      filtered,
                    ),
                ],
              ),
              if (canEdit)
                Positioned(
                  bottom: AppSpacing.space24,
                  right: AppSpacing.space24,
                  child: PanelFab(
                    label: l10n.panelQuickAddActivity,
                    onTap: () => _showAddSheet(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCategoryFilterSheet(
    BuildContext context,
    Set<ActivityCategory> selected,
  ) async {
    final cubit = context.read<ActivitiesViewCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<ActivitiesViewCubit>.value(
        value: cubit,
        child: const _CategoryFilterSheet(),
      ),
    );
  }

  List<Widget> _buildModeChildren(
    BuildContext context,
    AppLocalizations l10n,
    ActivitiesViewMode mode,
    List<Activity> filtered,
  ) {
    return switch (mode) {
      ActivitiesViewMode.timeline => _buildTimelineChildren(
        context,
        l10n,
        filtered,
      ),
      ActivitiesViewMode.list => _buildListChildren(context, l10n, filtered),
      ActivitiesViewMode.category => _buildCategoryChildren(
        context,
        l10n,
        filtered,
      ),
    };
  }

  List<Widget> _buildTimelineChildren(
    BuildContext context,
    AppLocalizations l10n,
    List<Activity> source,
  ) {
    final grouped = _groupByDayFor(source);
    final dayItems = _safeIndex < grouped.daily.length
        ? grouped.daily[_safeIndex]
        : <Activity>[];
    final unscheduled = grouped.unscheduled;

    return [
      if (_safeTotal > 1)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_safeTotal, (index) {
              final active = index == _safeIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    AppHaptics.light();
                    context.read<TripDetailBloc>().add(
                      SelectDay(dayIndex: index),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? ColorName.primaryDark : ColorName.surface,
                    ),
                    child: Text(
                      'J${index + 1}',
                      style: TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: active ? ColorName.surface : ColorName.hint,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      const SizedBox(height: AppSpacing.space16),
      if (dayItems.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space24),
          child: Center(
            child: Text(
              l10n.noActivitiesThisDay,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: ColorName.hint,
              ),
            ),
          ),
        )
      else
        ...dayItems.map((activity) => _activityRowFor(context, activity)),
      if (unscheduled.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.space24),
        _SectionLabel(text: l10n.activitiesUnscheduledHeader),
        ...unscheduled.map((activity) => _activityRowFor(context, activity)),
      ],
    ];
  }

  /// Flat chronological list. Scheduled activities ascending by date,
  /// then by start_time when same day, then unscheduled at the bottom
  /// (same affordance as the timeline view, just without the J-picker).
  List<Widget> _buildListChildren(
    BuildContext context,
    AppLocalizations l10n,
    List<Activity> source,
  ) {
    final scheduled = source.where((a) => a.date != null).toList()
      ..sort((a, b) {
        final byDate = a.date!.compareTo(b.date!);
        if (byDate != 0) return byDate;
        final aTime = a.startTime ?? '';
        final bTime = b.startTime ?? '';
        return aTime.compareTo(bTime);
      });
    final unscheduled = source.where((a) => a.date == null).toList();
    return [
      ...scheduled.map((activity) => _activityRowFor(context, activity)),
      if (unscheduled.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.space24),
        _SectionLabel(text: l10n.activitiesUnscheduledHeader),
        ...unscheduled.map((activity) => _activityRowFor(context, activity)),
      ],
    ];
  }

  /// Grouped by [ActivityCategory]. Each category is a labelled
  /// section with its activities sorted by date asc; an empty
  /// category is silently skipped (no point in surfacing buckets the
  /// user has nothing in).
  List<Widget> _buildCategoryChildren(
    BuildContext context,
    AppLocalizations l10n,
    List<Activity> source,
  ) {
    final byCategory = <ActivityCategory, List<Activity>>{};
    for (final activity in source) {
      byCategory.putIfAbsent(activity.category, () => []).add(activity);
    }
    final children = <Widget>[];
    for (final category in ActivityCategory.values) {
      final bucket = byCategory[category];
      if (bucket == null || bucket.isEmpty) continue;
      bucket.sort((a, b) {
        final aDate = a.date ?? DateTime(2999);
        final bDate = b.date ?? DateTime(2999);
        return aDate.compareTo(bDate);
      });
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.space24));
      }
      children
        ..add(_SectionLabel(text: category.label(l10n).toUpperCase()))
        ..addAll(bucket.map((activity) => _activityRowFor(context, activity)));
    }
    return children;
  }

  Widget _activityRowFor(BuildContext context, Activity activity) {
    return _ActivityRow(
      activity: activity,
      canEdit: canEdit,
      onTap: () => _showPreview(context, activity),
      onEdit: () => _showEditSheet(context, activity),
      onDelete: () => _delete(context, activity),
      onValidate: () => _validate(context, activity),
      categoryLabel: _categoryLabel,
    );
  }
}

/// Segmented picker for [ActivitiesViewMode]. Sits above the list and
/// lets the user pivot between the three layouts the panel supports.
/// Persistence lives in [ActivitiesViewCubit] — this widget is purely
/// presentational and reports the selection back via [onChanged].
class _ViewModePicker extends StatelessWidget {
  const _ViewModePicker({required this.selected, required this.onChanged});

  final ActivitiesViewMode selected;
  final ValueChanged<ActivitiesViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <(ActivitiesViewMode, String)>[
      (ActivitiesViewMode.timeline, l10n.activitiesViewTimeline),
      (ActivitiesViewMode.list, l10n.activitiesViewList),
      (ActivitiesViewMode.category, l10n.activitiesViewCategory),
    ];
    return Wrap(
      spacing: AppSpacing.space8,
      children: [
        for (final (mode, label) in entries)
          _ViewModeChip(
            label: label,
            isActive: mode == selected,
            onTap: () => onChanged(mode),
          ),
      ],
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  const _ViewModeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: isActive ? ColorName.primaryDark : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isActive
                ? ColorName.primaryDark
                : ColorName.primarySoftLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: isActive ? ColorName.surface : ColorName.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.space4,
        bottom: AppSpacing.space8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: ColorName.hint,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onValidate,
    required this.categoryLabel,
  });

  final Activity activity;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onValidate;
  final String Function(ActivityCategory) categoryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSuggested = activity.validationStatus == ValidationStatus.suggested;
    Widget tile = ActivityTile(
      title: activity.title,
      description: activity.description ?? '',
      category: categoryLabel(activity.category),
      onTap: onTap,
    );

    if (canEdit && isSuggested) {
      tile = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space16,
              0,
              AppSpacing.space16,
              AppSpacing.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InlineActionButton(
                    icon: Icons.check_rounded,
                    label: l10n.activityValidateAction,
                    accent: ColorName.secondary,
                    onTap: onValidate,
                  ),
                ),
                const SizedBox(width: AppSpacing.space8),
                Expanded(
                  child: _InlineActionButton(
                    icon: Icons.close_rounded,
                    label: l10n.panelActionDelete,
                    accent: ColorName.error,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!canEdit) return tile;

    return Dismissible(
      key: ValueKey('itinerary-panel-${activity.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        AppHaptics.medium();
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space16),
        decoration: const BoxDecoration(
          color: ColorName.error,
          borderRadius: AppRadius.large16,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AdaptiveContextMenu(
        actions: [
          AdaptiveContextAction(
            label: l10n.panelActionEdit,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
          AdaptiveContextAction(
            label: l10n.panelActionDelete,
            icon: Icons.delete_outline_rounded,
            onPressed: onDelete,
            isDestructive: true,
          ),
        ],
        child: tile,
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pill,
          border: Border.all(color: accent.withValues(alpha: 0.6)),
          color: accent.withValues(alpha: 0.05),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.space8,
          horizontal: AppSpacing.space12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPreviewBody extends StatelessWidget {
  const _ActivityPreviewBody({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = DateFormat.yMMMMEEEEd();
    final location = activity.location;
    final description = activity.description;
    final activityDate = activity.date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activityDate != null
              ? formatter.format(activityDate)
              : l10n.activitiesUnscheduledHeader,
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ColorName.primary,
          ),
        ),
        if (activity.startTime != null) ...[
          const SizedBox(height: 2),
          Text(
            '${activity.startTime}'
            '${activity.endTime != null ? ' — ${activity.endTime}' : ''}',
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              color: ColorName.hint,
            ),
          ),
        ],
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: ColorName.hint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    color: ColorName.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space16),
          Text(
            description,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 14,
              height: 1.5,
              color: ColorName.primaryDark,
            ),
          ),
        ],
        if (activity.validationStatus == ValidationStatus.suggested) ...[
          const SizedBox(height: AppSpacing.space16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: ColorName.secondary.withValues(alpha: 0.12),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              l10n.activitySuggestedBadge.toUpperCase(),
              style: const TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: ColorName.secondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Cross-cutting filter bar — sits between the view-mode picker and
/// the activity list. Shows a single-choice chip group for the
/// validation status (All / Suggested / Validated / Manual), an
/// "open category sheet" affordance, and a "clear" pill that only
/// surfaces when at least one filter is active.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.state,
    required this.onValidationChanged,
    required this.onCategoriesPressed,
    required this.onClearFilters,
  });

  final ActivitiesViewState state;
  final ValueChanged<ValidationStatus?> onValidationChanged;
  final VoidCallback onCategoriesPressed;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = <(ValidationStatus?, String)>[
      (null, l10n.activitiesFilterAll),
      (ValidationStatus.suggested, l10n.activitiesFilterSuggested),
      (ValidationStatus.validated, l10n.activitiesFilterValidated),
      (ValidationStatus.manual, l10n.activitiesFilterManual),
    ];
    final categoriesLabel = state.categoryFilters.isEmpty
        ? l10n.activitiesFilterCategoriesAction
        : '${l10n.activitiesFilterCategoriesAction} · ${state.categoryFilters.length}';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (status, label) in entries) ...[
            _FilterChip(
              label: label,
              isActive: state.validationFilter == status,
              onTap: () => onValidationChanged(status),
            ),
            const SizedBox(width: AppSpacing.space8),
          ],
          _FilterChip(
            label: categoriesLabel,
            isActive: state.categoryFilters.isNotEmpty,
            onTap: onCategoriesPressed,
            trailingIcon: Icons.tune_rounded,
          ),
          if (state.hasActiveFilters) ...[
            const SizedBox(width: AppSpacing.space8),
            _FilterChip(
              label: l10n.activitiesFilterClear,
              isActive: false,
              onTap: onClearFilters,
              trailingIcon: Icons.close_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: isActive ? ColorName.secondary : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isActive ? ColorName.secondary : ColorName.primarySoftLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? ColorName.surface : ColorName.primaryDark,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                trailingIcon,
                size: 12,
                color: isActive ? ColorName.surface : ColorName.primaryDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that surfaces every [ActivityCategory] as a checkbox.
/// Picks live in [ActivitiesViewCubit] — the sheet just toggles them
/// and lets the user dismiss when they're done.
class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.activitiesFilterCategoriesTitle,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 18,
                      color: ColorName.primaryDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.activitiesFilterDone,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontWeight: FontWeight.w600,
                        color: ColorName.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<ActivitiesViewCubit, ActivitiesViewState>(
              builder: (context, viewState) {
                return Column(
                  children: [
                    for (final category in ActivityCategory.values)
                      CheckboxListTile(
                        title: Text(
                          category.label(l10n),
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 14,
                            color: ColorName.primaryDark,
                          ),
                        ),
                        secondary: Icon(category.icon),
                        value: viewState.categoryFilters.contains(category),
                        onChanged: (_) => context
                            .read<ActivitiesViewCubit>()
                            .toggleCategoryFilter(category),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.space16),
          ],
        ),
      ),
    );
  }
}

/// Empty state surfaced when active filters reduce the list to zero.
/// Distinct from the "no activities at all" empty state on purpose:
/// the user did the filtering, the message explains the cause without
/// implying their trip has no content.
class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space32),
      child: Center(
        child: Text(
          l10n.activitiesFilterEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 14,
            color: ColorName.hint,
          ),
        ),
      ),
    );
  }
}
