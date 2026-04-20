import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Category keys recognized by [extractBudgetEntries]. Order drives the
/// display order in the legend + stripe segments.
const budgetCategoryKeys = <String>[
  'flights',
  'accommodation',
  'meals',
  'transport',
  'activities',
];

/// Extract a list of legend entries from a raw budget breakdown map coming
/// from the agent's `TripPlan` (numbers or `{amount: X}` shapes).
///
/// Skips zero / negative / missing amounts. The returned list is ordered to
/// match [budgetCategoryKeys] so callers can rely on stable visual ordering.
List<BudgetStripeEntry> extractBudgetEntries(
  AppLocalizations l10n,
  Map<String, dynamic> breakdown,
) {
  final entries = <BudgetStripeEntry>[];
  for (final key in budgetCategoryKeys) {
    final value = breakdown[key];
    double? amount;
    if (value is Map) {
      final raw = value['amount'];
      if (raw is num) amount = raw.toDouble();
    } else if (value is num) {
      amount = value.toDouble();
    }
    if (amount == null || amount <= 0) continue;
    entries.add(
      BudgetStripeEntry(
        label: budgetLabelForKey(key, l10n),
        amount: amount,
        color: budgetColorForKey(key),
      ),
    );
  }
  return entries;
}

String budgetLabelForKey(String key, AppLocalizations l10n) => switch (key) {
  'flights' => l10n.reviewBudgetFlights,
  'accommodation' => l10n.reviewBudgetAccommodation,
  'meals' => l10n.reviewBudgetMeals,
  'transport' => l10n.reviewBudgetTransport,
  'activities' => l10n.reviewBudgetActivities,
  _ => l10n.reviewBudgetOther,
};

Color budgetColorForKey(String key) => switch (key) {
  'flights' => ColorName.primary,
  'accommodation' => ColorName.primaryDark,
  'meals' => ColorName.warning,
  'transport' => AppColors.budgetTransport,
  'activities' => ColorName.secondary,
  _ => AppColors.budgetDefault,
};
