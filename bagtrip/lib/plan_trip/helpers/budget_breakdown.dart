import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/plan_trip/models/budget_breakdown.dart';
import 'package:flutter/material.dart';

/// Category keys recognized by [extractBudgetEntries]. Order drives the
/// display order in the legend + stripe segments.
///
/// Topic 05 (B12) — singular keys aligned with the `BudgetCategory` enum
/// (FLIGHT/ACCOMMODATION/FOOD/ACTIVITY/TRANSPORT). One source of truth
/// instead of a mapping table.
const budgetCategoryKeys = <String>[
  'flight',
  'accommodation',
  'food',
  'transport',
  'activity',
];

/// Extract a list of legend entries from a typed [BudgetBreakdown]
/// (B13). Replaces the old `Map<String, dynamic>` overload that
/// silently dropped categories on shape drift.
///
/// Skips zero / negative amounts. The returned list is ordered to
/// match [budgetCategoryKeys] so callers can rely on stable visual
/// ordering.
List<BudgetStripeEntry> extractBudgetEntries(
  AppLocalizations l10n,
  BudgetBreakdown breakdown,
) {
  final entries = <BudgetStripeEntry>[];
  final amounts = <String, double>{
    'flight': breakdown.flight,
    'accommodation': breakdown.accommodation,
    'food': breakdown.food,
    'transport': breakdown.transport,
    'activity': breakdown.activity,
  };
  for (final key in budgetCategoryKeys) {
    final amount = amounts[key] ?? 0;
    if (amount <= 0) continue;
    entries.add(
      BudgetStripeEntry(
        label: budgetLabelForKey(key, l10n),
        amount: amount,
        color: budgetColorForKey(key),
      ),
    );
  }
  if (breakdown.other > 0) {
    entries.add(
      BudgetStripeEntry(
        label: l10n.reviewBudgetOther,
        amount: breakdown.other,
        color: AppColors.budgetDefault,
      ),
    );
  }
  return entries;
}

String budgetLabelForKey(String key, AppLocalizations l10n) => switch (key) {
  'flight' => l10n.reviewBudgetFlights,
  'accommodation' => l10n.reviewBudgetAccommodation,
  'food' => l10n.reviewBudgetMeals,
  'transport' => l10n.reviewBudgetTransport,
  'activity' => l10n.reviewBudgetActivities,
  _ => l10n.reviewBudgetOther,
};

Color budgetColorForKey(String key) => switch (key) {
  'flight' => ColorName.primary,
  'accommodation' => ColorName.primaryDark,
  'food' => ColorName.warning,
  'transport' => AppColors.budgetTransport,
  'activity' => ColorName.secondary,
  _ => AppColors.budgetDefault,
};
