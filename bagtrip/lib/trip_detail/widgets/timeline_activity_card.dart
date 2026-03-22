import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

class TimelineActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isOwner;
  final bool isCompleted;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TimelineActivityCard({
    super.key,
    required this.activity,
    required this.isOwner,
    required this.isCompleted,
    this.onValidate,
    this.onReject,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSuggested = activity.validationStatus == ValidationStatus.suggested;

    final card = GestureDetector(
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
                  color: categoryColor(activity.category),
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
                          if (isSuggested) _AiBadge(label: l10n.aiBadgeLabel),
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
                  categoryIcon(activity.category),
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
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

    // Wrap in LongPressDraggable for drag & drop
    if (isOwner && !isCompleted) {
      final screenWidth = MediaQuery.of(context).size.width;
      return LongPressDraggable<Activity>(
        data: activity,
        delay: const Duration(milliseconds: 300),
        // haptics handled by the framework on long press start
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

    return dismissibleCard;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

IconData categoryIcon(ActivityCategory category) {
  return switch (category) {
    ActivityCategory.culture => Icons.museum_outlined,
    ActivityCategory.nature => Icons.park_outlined,
    ActivityCategory.food => Icons.restaurant_outlined,
    ActivityCategory.sport => Icons.fitness_center_outlined,
    ActivityCategory.shopping => Icons.shopping_bag_outlined,
    ActivityCategory.nightlife => Icons.nightlife_outlined,
    ActivityCategory.relaxation => Icons.spa_outlined,
    ActivityCategory.other => Icons.event_outlined,
  };
}

Color categoryColor(ActivityCategory category) {
  return switch (category) {
    ActivityCategory.culture => const Color(0xFF5C6BC0), // indigo
    ActivityCategory.nature => const Color(0xFF66BB6A), // green
    ActivityCategory.food => const Color(0xFFFF7043), // deepOrange
    ActivityCategory.sport => const Color(0xFF42A5F5), // blue
    ActivityCategory.shopping => const Color(0xFFAB47BC), // purple
    ActivityCategory.nightlife => const Color(0xFF7E57C2), // deepPurple
    ActivityCategory.relaxation => const Color(0xFF26A69A), // teal
    ActivityCategory.other => AppColors.secondary,
  };
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
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
