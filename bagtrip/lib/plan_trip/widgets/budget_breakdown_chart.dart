import 'package:bagtrip/components/staggered_fade_in.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/personalization_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BudgetBreakdownChart extends StatelessWidget {
  const BudgetBreakdownChart({
    super.key,
    required this.budgetBreakdown,
    required this.animationIndex,
  });

  final Map<String, dynamic> budgetBreakdown;
  final int animationIndex;

  static const _categoryKeys = [
    'flights',
    'accommodation',
    'meals',
    'transport',
    'activities',
  ];

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
    final entries = <_BudgetEntry>[];

    for (final key in _categoryKeys) {
      final value = budgetBreakdown[key];
      double? amount;
      if (value is Map) {
        final raw = value['amount'];
        if (raw is num) amount = raw.toDouble();
      } else if (value is num) {
        amount = value.toDouble();
      }
      if (amount == null || amount <= 0) {
        continue;
      }

      entries.add(
        _BudgetEntry(
          label: _labelForKey(key, l10n),
          amount: amount,
          color: _colorForKey(key),
        ),
      );
    }

    // Check for any remaining keys (other)
    for (final key in budgetBreakdown.keys) {
      if (_categoryKeys.contains(key) ||
          key == 'total_min' ||
          key == 'total_max' ||
          key == 'currency') {
        continue;
      }
      final value = budgetBreakdown[key];
      double? amount;
      if (value is Map) {
        final raw = value['amount'];
        if (raw is num) amount = raw.toDouble();
      } else if (value is num) {
        amount = value.toDouble();
      }
      if (amount == null || amount <= 0) continue;
      entries.add(
        _BudgetEntry(
          label: l10n.reviewBudgetOther,
          amount: amount,
          color: AppColors.categoryOther,
        ),
      );
    }

    return entries;
  }

  static String _labelForKey(String key, AppLocalizations l10n) =>
      switch (key) {
        'flights' => l10n.reviewBudgetFlights,
        'accommodation' => l10n.reviewBudgetAccommodation,
        'meals' => l10n.reviewBudgetMeals,
        'transport' => l10n.reviewBudgetTransport,
        'activities' => l10n.reviewBudgetActivities,
        _ => l10n.reviewBudgetOther,
      };

  static Color _colorForKey(String key) => switch (key) {
    'flights' => AppColors.categoryFlight,
    'accommodation' => AppColors.categoryAccommodation,
    'meals' => AppColors.categoryFood,
    'transport' => AppColors.categoryTransport,
    'activities' => AppColors.categoryActivity,
    _ => AppColors.categoryOther,
  };
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
