import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isViewer;

  const BudgetItemCard({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
    this.isViewer = false,
  });

  bool get _isConfirmed => item.sourceType != null || !item.isPlanned;

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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = _isConfirmed;
    final opacity = confirmed ? 1.0 : 0.6;

    return Opacity(
      opacity: opacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.medium8,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: confirmed
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.cornerRaidus8),
                    bottomLeft: Radius.circular(AppRadius.cornerRaidus8),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_categoryIcon(item.category)),
                  ),
                  title: Text(
                    item.label,
                    style: confirmed
                        ? null
                        : const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isViewer)
                        Text(
                          '${item.amount.toStringAsFixed(2)} \u20ac',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      if (item.date != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(item.date!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: AppSpacing.space4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: confirmed
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: AppRadius.pill,
                            ),
                            child: Text(
                              confirmed
                                  ? l10n.budgetConfirmed
                                  : l10n.budgetForecasted,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: confirmed
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: isViewer || (onEdit == null && onDelete == null)
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') onEdit?.call();
                            if (value == 'delete') onDelete?.call();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.editButton),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.deleteButton),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
