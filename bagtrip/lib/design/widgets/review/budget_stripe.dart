import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// One labelled + colored entry inside a [BudgetStripe].
class BudgetStripeEntry {
  const BudgetStripeEntry({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;
}

/// A rounded segment of the horizontal stripe above the legend.
class BudgetSegment extends StatelessWidget {
  const BudgetSegment({
    super.key,
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(100) : Radius.zero,
          right: isLast ? const Radius.circular(100) : Radius.zero,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Total + colored stripe + entry legend, in a single white card.
///
/// Pure presentation: the caller decides how to extract [entries] from
/// whatever data it holds (see `plan_trip/helpers/budget_breakdown.dart` for
/// the wizard's extractor).
class BudgetStripe extends StatelessWidget {
  const BudgetStripe({
    super.key,
    required this.total,
    required this.entries,
    required this.subtitle,
    this.onEntryTap,
  });

  final double total;
  final List<BudgetStripeEntry> entries;

  /// Small caption on the right of the total (e.g. "Estimation · 7 days").
  final String subtitle;

  /// When provided, each legend row becomes tappable.
  final ValueChanged<int>? onEntryTap;

  static const _ink = AppColors.reviewInk;

  @override
  Widget build(BuildContext context) {
    final sum = entries.fold<double>(0, (value, entry) => value + entry.amount);
    final resolvedTotal = total > 0 ? total : sum;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.large16,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  resolvedTotal.formatPrice(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.5,
                    color: _ink,
                    height: 1,
                  ),
                ),
                Flexible(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: _ink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty && sum > 0)
              Container(
                height: 6,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                child: Row(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Expanded(
                        flex: ((entries[i].amount / sum) * 1000).round().clamp(
                          1,
                          1000,
                        ),
                        child: BudgetSegment(
                          color: entries[i].color,
                          isFirst: i == 0,
                          isLast: i == entries.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
            for (var i = 0; i < entries.length; i++)
              _LegendRow(
                entry: entries[i],
                onTap: onEntryTap == null ? null : () => onEntryTap!(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.entry, required this.onTap});

  final BudgetStripeEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.label,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: AppColors.reviewInk.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            entry.amount.formatPrice(),
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: AppColors.reviewInk,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
