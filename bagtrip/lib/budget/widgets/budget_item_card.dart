import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/status_badge.dart';
import 'package:bagtrip/gen/colors.gen.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = _isConfirmed;
    final textColor = confirmed
        ? AppColors.onSurface
        : AppColors.onSurface.withValues(alpha: 0.6);
    final iconColor = confirmed
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
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
          CircleAvatar(
            child: Icon(_categoryIcon(item.category), color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: textColor,
                          fontStyle: confirmed
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      type: confirmed
                          ? StatusType.confirmed
                          : StatusType.forecasted,
                    ),
                  ],
                ),
                if (!isViewer)
                  Text(
                    '${item.amount.toStringAsFixed(2)} \u20ac',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                if (item.date != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(item.date!),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: textColor),
                  ),
              ],
            ),
          ),
          if (!isViewer && (onEdit != null || onDelete != null))
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.editButton)),
                PopupMenuItem(value: 'delete', child: Text(l10n.deleteButton)),
              ],
            ),
        ],
      ),
    );
  }
}
