import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isViewer;

  const BudgetItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.isViewer = false,
  });

  IconData _categoryIcon(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.flight:
        return Icons.flight;
      case BudgetCategory.accommodation:
        return Icons.hotel;
      case BudgetCategory.food:
        return Icons.restaurant;
      case BudgetCategory.activity:
        return Icons.sports_tennis;
      case BudgetCategory.transport:
        return Icons.directions_car;
      case BudgetCategory.other:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(_categoryIcon(item.category))),
        title: Text(item.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isViewer)
              Text(
                '${item.amount.toStringAsFixed(2)} \u20ac',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            if (item.date != null)
              Text(
                DateFormat('dd/MM/yyyy').format(item.date!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    item.isPlanned
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.isPlanned ? 'Planned' : 'Real',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: item.isPlanned ? Colors.blue : Colors.green,
                ),
              ),
            ),
          ],
        ),
        trailing:
            isViewer
                ? null
                : PopupMenuButton<String>(
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
