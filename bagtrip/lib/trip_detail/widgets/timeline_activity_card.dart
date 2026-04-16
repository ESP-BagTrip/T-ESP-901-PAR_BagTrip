import 'package:bagtrip/components/adaptive/adaptive_context_menu.dart';
import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/category_mappers.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimelineActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isOwner;
  final bool isCompleted;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final int totalDays;
  final DateTime? tripStartDate;
  final void Function(int dayIndex)? onMoveToDay;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    required this.isOwner,
    required this.isCompleted,
    this.onValidate,
    this.onReject,
    this.onDelete,
    this.onEdit,
    this.totalDays = 1,
    this.tripStartDate,
    this.onMoveToDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSuggested = activity.validationStatus == ValidationStatus.suggested;

    final card = Semantics(
      button: true,
      label: l10n.timelineActivitySemanticLabel(
        activity.title,
        activity.startTime ?? l10n.activeTripsAllDay,
        activity.location ?? '',
      ),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: (isOwner && !isCompleted && onEdit != null)
            ? () {
                AppHaptics.light();
                onEdit!.call();
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: AppRadius.large16,
            boxShadow: [
              BoxShadow(color: AppColors.shadowLight, blurRadius: 8),
              BoxShadow(color: AppColors.shadowFaint, blurRadius: 2),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: activity.category.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time row + AI badge
                        Row(
                          children: [
                            Text(
                              activity.startTime ?? l10n.activeTripsAllDay,
                              style: const TextStyle(
                                fontFamily: FontFamily.b612,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            if (activity.endTime != null)
                              Text(
                                ' - ${activity.endTime}',
                                style: TextStyle(
                                  fontFamily: FontFamily.b612,
                                  fontSize: 13,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            const Spacer(),
                            if (isSuggested)
                              Semantics(
                                label: l10n.aiBadgeLabel,
                                child: _AiBadge(label: l10n.aiBadgeLabel),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Title
                        Text(
                          activity.title,
                          style: TextStyle(
                            fontFamily: FontFamily.b612,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Location
                        if (activity.location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  activity.location!,
                                  style: TextStyle(
                                    fontFamily: FontFamily.b612,
                                    fontSize: 12,
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Validate / Reject actions
                        if (isSuggested && isOwner && !isCompleted) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _ActionChip(
                                icon: Icons.check,
                                label: l10n.timelineValidate,
                                onTap: () {
                                  AppHaptics.medium();
                                  onValidate?.call();
                                },
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              _ActionChip(
                                icon: Icons.close,
                                label: l10n.timelineReject,
                                onTap: () {
                                  AppHaptics.light();
                                  onReject?.call();
                                },
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Category icon
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    activity.category.icon,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap in Dismissible for owners
    Widget dismissibleCard = card;
    if (isOwner && !isCompleted) {
      dismissibleCard = Dismissible(
        key: ValueKey(activity.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.space24),
          decoration: const BoxDecoration(
            color: AppColors.error,
            borderRadius: AppRadius.large16,
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onDelete?.call(),
        child: card,
      );
    }

    // Wrap in gesture handler for owners
    if (isOwner && !isCompleted) {
      if (AdaptivePlatform.isIOS) {
        // iOS: CupertinoContextMenu replaces LongPressDraggable
        final l10n = AppLocalizations.of(context)!;
        final actions = <AdaptiveContextAction>[
          if (onEdit != null)
            AdaptiveContextAction(
              label: l10n.contextMenuEdit,
              icon: CupertinoIcons.pencil,
              onPressed: onEdit!,
            ),
          if (activity.validationStatus == ValidationStatus.suggested &&
              onValidate != null)
            AdaptiveContextAction(
              label: l10n.contextMenuValidate,
              icon: CupertinoIcons.checkmark_circle,
              onPressed: onValidate!,
            ),
          if (totalDays > 1 && onMoveToDay != null)
            AdaptiveContextAction(
              label: l10n.contextMenuMoveToDay,
              icon: CupertinoIcons.calendar,
              onPressed: () => _showDayPicker(context),
            ),
          if (onDelete != null)
            AdaptiveContextAction(
              label: l10n.contextMenuDelete,
              icon: CupertinoIcons.delete,
              onPressed: onDelete!,
              isDestructive: true,
            ),
        ];
        return AdaptiveContextMenu(actions: actions, child: dismissibleCard);
      } else {
        // Android: keep LongPressDraggable as-is
        final screenWidth = MediaQuery.of(context).size.width;
        return LongPressDraggable<Activity>(
          data: activity,
          delay: const Duration(milliseconds: 300),
          feedback: Material(
            elevation: 8,
            borderRadius: AppRadius.large16,
            child: SizedBox(
              width: screenWidth - 64,
              child: Opacity(opacity: 0.9, child: card),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: dismissibleCard),
          child: dismissibleCard,
        );
      }
    }

    return dismissibleCard;
  }

  int get _currentDayIndex {
    if (tripStartDate == null) return 0;
    return DateTime(activity.date.year, activity.date.month, activity.date.day)
        .difference(
          DateTime(
            tripStartDate!.year,
            tripStartDate!.month,
            tripStartDate!.day,
          ),
        )
        .inDays;
  }

  void _showDayPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM');

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.contextMenuMoveToDay),
        actions: List.generate(totalDays, (i) {
          if (i == _currentDayIndex) return null;
          final date = tripStartDate!.add(Duration(days: i));
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              onMoveToDay?.call(i);
            },
            child: Text(
              '${l10n.contextMenuDayLabel(i + 1)} — ${dateFormat.format(date)}',
            ),
          );
        }).whereType<CupertinoActionSheetAction>().toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancelButton),
        ),
      ),
    );
  }
}

// ── AI Badge ─────────────────────────────────────────────────────────────────

class _AiBadge extends StatelessWidget {
  final String label;
  const _AiBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.b612,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

// ── Action Chip ──────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
