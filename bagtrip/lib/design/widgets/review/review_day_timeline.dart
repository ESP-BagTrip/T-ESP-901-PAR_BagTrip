import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/review_day_card.dart';
import 'package:flutter/material.dart';

/// Vertical sequence of day cards. No section header — the cinematic hero
/// already locates the reader; days stream straight into the scroll.
class ReviewDayTimeline extends StatelessWidget {
  const ReviewDayTimeline({
    super.key,
    required this.days,
    required this.freeDayLabel,
    required this.dayTitleBuilder,
  });

  final List<ReviewDayCardData> days;
  final String freeDayLabel;

  /// Builds the pre-formatted day title ("Day 1 · Mon 12 Apr").
  final String Function(ReviewDayCardData data) dayTitleBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.space32),
        for (var i = 0; i < days.length; i++) ...[
          ReviewDayCard(
            data: days[i],
            freeDayLabel: freeDayLabel,
            dayTitle: dayTitleBuilder(days[i]),
          ),
          if (i < days.length - 1) const SizedBox(height: AppSpacing.space16),
        ],
      ],
    );
  }
}
