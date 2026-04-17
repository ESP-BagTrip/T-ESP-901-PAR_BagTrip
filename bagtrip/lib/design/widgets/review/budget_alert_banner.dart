import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';

/// Unified alert banner for budget thresholds. Supersedes both the legacy
/// `BudgetAlertBanner` (budget subpage) and the inline `_OverBudgetBanner`
/// (budget panel). Returns [SizedBox.shrink] when no alert is active so the
/// caller can mount it unconditionally.
class BudgetAlertBanner extends StatelessWidget {
  const BudgetAlertBanner({super.key, required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final level = summary.alertLevel;
    if (level == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final isDanger = level == 'DANGER';

    final Color bg = isDanger ? AppColors.dangerBg : AppColors.warningBg;
    final Color border = isDanger
        ? AppColors.dangerBorder
        : AppColors.warningBorder;
    final Color iconColor = isDanger
        ? AppColors.dangerIcon
        : AppColors.warningIcon;
    final Color textColor = isDanger
        ? AppColors.dangerText
        : AppColors.warningText;
    final IconData icon = isDanger
        ? Icons.error_outline_rounded
        : Icons.warning_amber_rounded;

    final String message;
    if (isDanger) {
      final over = (summary.totalSpent - summary.totalBudget).clamp(0, 1e9);
      message = l10n.budgetExceeded(over.toDouble().formatPrice());
    } else {
      final pct = summary.totalBudget > 0
          ? (summary.totalSpent / summary.totalBudget * 100).round()
          : 0;
      message = l10n.budgetWarning(pct.toString());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.large16,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: FontFamily.dMSans,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
