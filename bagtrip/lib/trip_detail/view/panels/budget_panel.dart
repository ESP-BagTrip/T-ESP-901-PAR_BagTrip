import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/budget_alert_banner.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:bagtrip/plan_trip/helpers/budget_breakdown.dart';
import 'package:flutter/material.dart';

/// Budget tab: [BudgetStripe] with totals + legend entries, optional
/// over-budget banner, and a tap affordance that routes to the full
/// `/budget` page for add/edit.
class BudgetPanel extends StatelessWidget {
  const BudgetPanel({
    super.key,
    required this.tripId,
    required this.budgetSummary,
    required this.totalDays,
    required this.canEdit,
    required this.isCompleted,
    required this.role,
  });

  final String tripId;
  final BudgetSummary? budgetSummary;
  final int totalDays;
  final bool canEdit;
  final bool isCompleted;
  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = budgetSummary;
    if (summary == null ||
        (summary.totalBudget <= 0 && summary.byCategory.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: ElegantEmptyState(
          icon: Icons.account_balance_wallet_rounded,
          title: l10n.emptyBudgetTitle,
          subtitle: canEdit ? l10n.emptyBudgetSubtitle : null,
        ),
      );
    }

    final entries = _breakdownEntries(summary, l10n);
    final hasAlert = summary.alertLevel != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space24,
      ),
      children: [
        if (hasAlert) BudgetAlertBanner(summary: summary),
        if (hasAlert) const SizedBox(height: AppSpacing.space12),
        BudgetStripe(
          total: summary.totalBudget,
          entries: entries,
          subtitle: _subtitle(l10n),
        ),
        const SizedBox(height: AppSpacing.space16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.large16,
            onTap: () => BudgetRoute(
              tripId: tripId,
              role: role,
              isCompleted: isCompleted,
            ).push(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, color: ColorName.primary),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Text(
                      l10n.budgetSeeAllExpenses,
                      style: const TextStyle(
                        fontFamily: FontFamily.dMSerifDisplay,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ColorName.primaryDark,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _subtitle(AppLocalizations l10n) {
    if (totalDays <= 0) return l10n.reviewBudgetEstimationPrefix;
    return '${l10n.reviewBudgetEstimationPrefix} · ${l10n.summaryDaysCount(totalDays)}';
  }

  List<BudgetStripeEntry> _breakdownEntries(
    BudgetSummary summary,
    AppLocalizations l10n,
  ) {
    final remapped = <String, dynamic>{};
    summary.byCategory.forEach((key, value) {
      final normalized = _normalize(key);
      if (normalized != null) remapped[normalized] = value;
    });
    return extractBudgetEntries(l10n, remapped);
  }

  String? _normalize(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('flight')) return 'flights';
    if (lower.contains('accommodation') || lower.contains('hotel')) {
      return 'accommodation';
    }
    if (lower.contains('food') || lower.contains('meal')) return 'meals';
    if (lower.contains('transport')) return 'transport';
    if (lower.contains('activit')) return 'activities';
    return null;
  }
}
