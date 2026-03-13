import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';

class BudgetSummaryHeader extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetSummaryHeader({super.key, required this.summary});

  Color _progressColor(double ratio) {
    if (ratio > 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final ratio =
        summary.totalBudget > 0
            ? summary.totalSpent / summary.totalBudget
            : 0.0;
    final color = _progressColor(ratio);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AmountLabel(
                  label: 'Total Budget',
                  amount: summary.totalBudget,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _AmountLabel(
                  label: 'Spent',
                  amount: summary.totalSpent,
                  color: color,
                ),
                _AmountLabel(
                  label: 'Remaining',
                  amount: summary.remaining,
                  color: summary.remaining >= 0 ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            if (ratio > 1.0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Over budget by ${(summary.totalSpent - summary.totalBudget).toStringAsFixed(2)} \u20ac',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountLabel({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} \u20ac',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
