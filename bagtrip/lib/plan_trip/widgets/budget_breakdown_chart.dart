import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:flutter/material.dart';

class BudgetBreakdownChart extends StatelessWidget {
  const BudgetBreakdownChart({
    super.key,
    required this.budgetBreakdown,
    required this.animationIndex,
  });

  final BudgetBreakdown budgetBreakdown;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = _extractEntries(l10n);
    if (entries.isEmpty) return const SizedBox.shrink();

    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);

    return StaggeredFadeIn(
      index: animationIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: AppRadius.medium8,
            child: SizedBox(
              height: 12,
              child: Row(
                children: entries.map((e) {
                  final fraction = total > 0 ? e.amount / total : 0.0;
                  return Expanded(
                    flex: (fraction * 1000).round().clamp(1, 1000),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      color: e.color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          // Legend rows
          ...entries.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            return StaggeredFadeIn(
              index: idx,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Text(
                      entry.label,
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        color: PersonalizationColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.reviewPriceEur(entry.amount.toStringAsFixed(0)),
                      style: const TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: PersonalizationColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(height: AppSpacing.space24),
          // Total
          Row(
            children: [
              Text(
                l10n.reviewBudgetTotal,
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: PersonalizationColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.reviewPriceEur(total.toStringAsFixed(0)),
                style: const TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_BudgetEntry> _extractEntries(AppLocalizations l10n) {
    final pairs = <(double, String, Color)>[
      (
        budgetBreakdown.flight,
        l10n.reviewBudgetFlights,
        AppColors.categoryFlight,
      ),
      (
        budgetBreakdown.accommodation,
        l10n.reviewBudgetAccommodation,
        AppColors.categoryAccommodation,
      ),
      (budgetBreakdown.food, l10n.reviewBudgetMeals, AppColors.categoryFood),
      (
        budgetBreakdown.transport,
        l10n.reviewBudgetTransport,
        AppColors.categoryTransport,
      ),
      (
        budgetBreakdown.activity,
        l10n.reviewBudgetActivities,
        AppColors.categoryActivity,
      ),
      (budgetBreakdown.other, l10n.reviewBudgetOther, AppColors.categoryOther),
    ];

    return [
      for (final (amount, label, color) in pairs)
        if (amount > 0)
          _BudgetEntry(label: label, amount: amount, color: color),
    ];
  }
}

class _BudgetEntry {
  const _BudgetEntry({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}
