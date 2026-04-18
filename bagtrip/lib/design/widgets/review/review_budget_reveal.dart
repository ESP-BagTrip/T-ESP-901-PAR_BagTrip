import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// "Moment of truth" section — big serif total headlined over a rich card,
/// per-person line muted underneath, stripe chart revealing how the money
/// breaks down. Rendered right before the decision inline.
class ReviewBudgetReveal extends StatelessWidget {
  const ReviewBudgetReveal({
    super.key,
    required this.header,
    required this.perPersonLabel,
    required this.total,
    required this.entries,
    required this.subtitle,
  });

  final String header;
  final String perPersonLabel;
  final double total;
  final List<BudgetStripeEntry> entries;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space40,
        AppSpacing.space16,
        AppSpacing.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.space8),
            child: Text(
              header.toUpperCase(),
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.reviewFaint.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF122B48), ColorName.primaryDark],
              ),
              borderRadius: AppRadius.large24,
              boxShadow: [
                BoxShadow(
                  color: ColorName.primaryDark.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space24,
                AppSpacing.space24,
                AppSpacing.space24,
                AppSpacing.space24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total.formatPrice(),
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSerifDisplay,
                      fontSize: 64,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -2,
                      color: Colors.white,
                    ),
                  ),
                  if (perPersonLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      perPersonLabel,
                      style: TextStyle(
                        fontFamily: FontFamily.dMSans,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                  if (entries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space16),
                    _GradientStripe(entries: entries),
                    const SizedBox(height: AppSpacing.space16),
                    _LegendGrid(entries: entries),
                  ],
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: FontFamily.b612,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientStripe extends StatelessWidget {
  const _GradientStripe({required this.entries});

  final List<BudgetStripeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sum = entries.fold<double>(0, (value, entry) => value + entry.amount);
    if (sum <= 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            for (var i = 0; i < entries.length; i++)
              Expanded(
                flex: ((entries[i].amount / sum) * 1000).round().clamp(1, 1000),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: entries[i].color),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendGrid extends StatelessWidget {
  const _LegendGrid({required this.entries});

  final List<BudgetStripeEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entries[i].color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Text(
                    entries[i].label,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Text(
                  entries[i].amount.formatPrice(),
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
