import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:flutter/material.dart';

class BudgetSummaryHeader extends StatelessWidget {
  final BudgetSummary summary;
  final bool isViewer;

  const BudgetSummaryHeader({
    super.key,
    required this.summary,
    this.isViewer = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirmedRatio = summary.totalBudget > 0
        ? summary.confirmedTotal / summary.totalBudget
        : 0.0;
    final forecastedRatio = summary.totalBudget > 0
        ? (summary.confirmedTotal + summary.forecastedTotal) /
              summary.totalBudget
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space16),
      padding: AppSpacing.allEdgeInsetSpace16,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountColumn(
                label: l10n.budgetTotal,
                amount: summary.totalBudget,
                color: AppColors.primary,
                isLarge: true,
              ),
              _AmountColumn(
                label: l10n.budgetConfirmed,
                amount: summary.confirmedTotal,
                color: AppColors.primary,
                indicator: _IndicatorStyle.solid,
              ),
              _AmountColumn(
                label: l10n.budgetForecasted,
                amount: summary.forecastedTotal,
                color: AppColors.primary,
                indicator: _IndicatorStyle.dashed,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          // Stacked progress bars
          SizedBox(
            height: 8,
            child: ClipRRect(
              borderRadius: AppRadius.small4,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.small4,
                    ),
                  ),
                  // Forecasted bar (behind, lighter)
                  FractionallySizedBox(
                    widthFactor: forecastedRatio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: AppRadius.small4,
                      ),
                    ),
                  ),
                  // Confirmed bar (front, solid)
                  FractionallySizedBox(
                    widthFactor: confirmedRatio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.small4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isViewer && summary.percentConsumed != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space4),
              child: Text(
                '${summary.percentConsumed!.toStringAsFixed(0)}% consumed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.hint,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _IndicatorStyle { solid, dashed }

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isLarge;
  final _IndicatorStyle? indicator;

  const _AmountColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.isLarge = false,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (indicator != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space4),
            child: _buildIndicator(),
          ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.hint),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          '${amount.toStringAsFixed(2)} \u20ac',
          style: isLarge
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                )
              : Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
        ),
      ],
    );
  }

  Widget _buildIndicator() {
    if (indicator == _IndicatorStyle.dashed) {
      return SizedBox(
        width: 24,
        height: 4,
        child: CustomPaint(painter: _DashedLinePainter(color: color)),
      );
    }
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.small4),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
