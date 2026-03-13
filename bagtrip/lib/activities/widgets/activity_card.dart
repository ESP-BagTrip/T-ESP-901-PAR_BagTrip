import 'package:bagtrip/models/activity.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_categoryIcon(activity.category))),
        title: Text(activity.title),
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
            if (activity.estimatedCost != null)
              Text(
                '${activity.estimatedCost!.toStringAsFixed(2)} \u20ac',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder:
              (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
        ),
      ),
    );
  }
}
