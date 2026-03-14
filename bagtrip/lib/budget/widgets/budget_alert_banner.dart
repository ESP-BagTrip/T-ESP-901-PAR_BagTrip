import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';

class BudgetAlertBanner extends StatelessWidget {
  final BudgetSummary summary;

  const BudgetAlertBanner({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDanger = summary.alertLevel == 'DANGER';

    final bgColor = isDanger ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = isDanger ? Colors.red.shade300 : Colors.orange.shade300;
    final iconColor = isDanger ? Colors.red.shade700 : Colors.orange.shade700;
    final textColor = isDanger ? Colors.red.shade900 : Colors.orange.shade900;
    final icon = isDanger ? Icons.error : Icons.warning;

    final String message;
    if (isDanger) {
      final over = summary.totalSpent - summary.totalBudget;
      message = l10n.budgetExceeded(over.toStringAsFixed(2));
    } else {
      final pct = summary.totalBudget > 0
          ? (summary.totalSpent / summary.totalBudget * 100).round()
          : 0;
      message = l10n.budgetWarning(pct.toString());
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
