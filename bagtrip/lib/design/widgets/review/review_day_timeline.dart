import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/review_day_card.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Vertical sequence of day cards introduced by an editorial section header.
/// Each day is a raised card so the scroll feels rhythmic and paginated.
class ReviewDayTimeline extends StatelessWidget {
  const ReviewDayTimeline({
    super.key,
    required this.header,
    required this.days,
    required this.freeDayLabel,
    required this.dayTitleBuilder,
  });

  final String header;
  final List<ReviewDayCardData> days;
  final String freeDayLabel;

  /// Builds the pre-formatted day title ("Day 1 · Mon 12 Apr").
  final String Function(ReviewDayCardData data) dayTitleBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space24,
            AppSpacing.space24,
            AppSpacing.space24,
            AppSpacing.space16,
          ),
          child: Text(
            header,
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.6,
              color: AppColors.reviewInk,
            ),
          ),
        ),
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
