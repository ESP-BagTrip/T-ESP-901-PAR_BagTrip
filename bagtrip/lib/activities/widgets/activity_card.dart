import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/status_badge.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onValidate;
  final bool isViewer;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
    this.onValidate,
    this.isViewer = false,
  });

  IconData _categoryIcon(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.visit:
        return Icons.museum;
      case ActivityCategory.restaurant:
        return Icons.restaurant;
      case ActivityCategory.transport:
        return Icons.directions_car;
      case ActivityCategory.leisure:
        return Icons.sports_tennis;
      case ActivityCategory.culture:
        return Icons.theater_comedy;
      case ActivityCategory.nature:
        return Icons.park;
      case ActivityCategory.other:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: ColorName.primary.withValues(alpha: 0.04),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Icon(_categoryIcon(activity.category))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(activity.title)),
                    if (activity.validationStatus ==
                        ValidationStatus.suggested) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(type: StatusType.pending),
                    ],
                    if (activity.validationStatus ==
                        ValidationStatus.validated) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(type: StatusType.confirmed),
                    ],
                  ],
                ),
                if (activity.startTime != null || activity.endTime != null)
                  Text(
                    [
                      activity.startTime,
                      activity.endTime,
                    ].whereType<String>().join(' - '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (activity.location != null)
                  Text(
                    activity.location!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (activity.estimatedCost != null && !isViewer)
                  Text(
                    '${activity.estimatedCost!.toStringAsFixed(2)} \u20ac',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (!isViewer)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
                if (value == 'validate') onValidate?.call();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
                if (activity.validationStatus == ValidationStatus.suggested)
                  PopupMenuItem(
                    value: 'validate',
                    child: Text(l10n.activityValidateConfirm),
                  ),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
              ],
            ),
        ],
      ),
    );
  }
}
