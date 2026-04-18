import 'package:bagtrip/activities/widgets/activity_form.dart';
import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/activity_tile.dart';
import 'package:bagtrip/design/widgets/review/panel_fab.dart';
import 'package:bagtrip/design/widgets/review/sheets/quick_preview_sheet.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Itinerary tab — day selector on top + activities for the selected day.
///
/// Tapping an activity opens a [QuickPreviewSheet] with Validate (for
/// suggestions) / Edit / Delete actions — navigation to `/activities`
/// only happens if the user explicitly taps "Open full itinerary" inside
/// that sheet or the footer. Swipe-to-delete and long-press context
/// menu bring the same actions to hand without modals.
class ItineraryPanel extends StatelessWidget {
  const ItineraryPanel({
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

  DateTime _dayDateFor(int index) {
    if (tripStartDate != null) {
      return tripStartDate!.add(Duration(days: index));
    }
    if (activities.isEmpty) return DateTime.now().add(Duration(days: index));
    final earliest = activities
        .map((a) => a.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(
      earliest.year,
      earliest.month,
      earliest.day,
    ).add(Duration(days: index));
  }

  int _dayIndexFor(Activity activity) {
    if (activities.isEmpty) return 0;
    final earliest = activities
        .map((a) => a.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final base = DateTime(earliest.year, earliest.month, earliest.day);
    final current = DateTime(
      activity.date.year,
      activity.date.month,
      activity.date.day,
    );
    return current.difference(base).inDays.clamp(0, _safeTotal - 1);
  }

  List<List<Activity>> _groupByDay() {
    final groups = List<List<Activity>>.generate(_safeTotal, (_) => []);
    final sorted = [...activities]..sort((a, b) => a.date.compareTo(b.date));
    for (final activity in sorted) {
      groups[_dayIndexFor(activity)].add(activity);
    }
    return groups;
  }

  String _categoryLabel(ActivityCategory category) => switch (category) {
    ActivityCategory.culture => 'CULTURE',
    ActivityCategory.nature => 'NATURE',
    ActivityCategory.food => 'FOOD',
    ActivityCategory.sport => 'SPORT',
    ActivityCategory.shopping => 'SHOP',
    ActivityCategory.nightlife => 'NIGHT',
    ActivityCategory.relaxation => 'RELAX',
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

    final grouped = _groupByDay();
    final dayItems = _safeIndex < grouped.length
        ? grouped[_safeIndex]
        : <Activity>[];

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
                            color: active
                                ? ColorName.primaryDark
                                : ColorName.surface,
                          ),
                          child: Text(
                            'J${index + 1}',
                            style: TextStyle(
                              fontFamily: FontFamily.dMSerifDisplay,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: active
                                  ? ColorName.surface
                                  : ColorName.hint,
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
              ...dayItems.map(
                (activity) => _ActivityRow(
                  activity: activity,
                  canEdit: canEdit,
                  onTap: () => _showPreview(context, activity),
                  onEdit: () => _showEditSheet(context, activity),
                  onDelete: () => _delete(context, activity),
                  onValidate: () => _validate(context, activity),
                  categoryLabel: _categoryLabel,
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatter.format(activity.date),
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
