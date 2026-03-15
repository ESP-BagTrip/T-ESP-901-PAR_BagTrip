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
      case ActivityCategory.other:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_categoryIcon(activity.category))),
        title: Row(
          children: [
            Flexible(child: Text(activity.title)),
            if (activity.validationStatus == ValidationStatus.suggested)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.activityToValidate,
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (activity.validationStatus == ValidationStatus.validated)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.activityValidated,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: isViewer
            ? null
            : PopupMenuButton<String>(
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
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.deleteButton),
                  ),
                ],
              ),
      ),
    );
  }
}
