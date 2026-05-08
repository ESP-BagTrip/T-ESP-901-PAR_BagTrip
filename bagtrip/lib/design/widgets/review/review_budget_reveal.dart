import 'package:bagtrip/core/extensions/price_format_ext.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/budget_stripe.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Budget section — a deep ink card that frames the total as a proposition.
/// Big serif number, per-person whisper, hairline legend.
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
        AppSpacing.space8,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1F35),
          borderRadius: AppRadius.large24,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1F35).withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header.toUpperCase(),
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.2,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: AppSpacing.space24),
              Text(
                total.formatPrice(),
                style: const TextStyle(
                  fontFamily: FontFamily.dMSerifDisplay,
                  fontSize: 72,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -3,
                  color: Colors.white,
                ),
              ),
              if (perPersonLabel.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space8),
                Text(
                  perPersonLabel,
                  style: TextStyle(
                    fontFamily: FontFamily.dMSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
              if (entries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space24),
                Container(
                  height: 0.5,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: AppSpacing.space16),
                _Legend(entries: entries),
              ],
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space16),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: FontFamily.b612,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<BudgetStripeEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: entries[i].color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space16),
                Expanded(
                  child: Text(
                    entries[i].label,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                Text(
                  entries[i].displayOverride ?? entries[i].amount.formatPrice(),
                  style: TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: entries[i].deferred
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white,
                    fontStyle: entries[i].deferred
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          if (i < entries.length - 1)
            Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
        ],
      ],
    );
  }
}
