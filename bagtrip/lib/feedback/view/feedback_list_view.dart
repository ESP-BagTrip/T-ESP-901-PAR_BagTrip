import 'package:bagtrip/components/elegant_empty_state.dart';
import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedbackListView extends StatelessWidget {
  final List<TripFeedback> feedbacks;

  const FeedbackListView({super.key, required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return ElegantEmptyState(
        icon: Icons.rate_review_outlined,
        title: AppLocalizations.of(context)!.feedbackNoReviews,
      );
    }

    return ListView.builder(
      padding: AppSpacing.allEdgeInsetSpace16,
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.space12),
          child: Padding(
            padding: AppSpacing.allEdgeInsetSpace16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < feedback.overallRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 20,
                        color: AppColors.starRating,
                      );
                    }),
                    const Spacer(),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(feedback.createdAt ?? DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (feedback.highlights != null) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.feedbackHighlightsPrefix(feedback.highlights!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (feedback.lowlights != null) ...[
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.feedbackLowlightsPrefix(feedback.lowlights!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.space8),
                Row(
                  children: [
                    Icon(
                      feedback.wouldRecommend
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      size: 16,
                      color: feedback.wouldRecommend
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    Text(
                      feedback.wouldRecommend
                          ? AppLocalizations.of(context)!.feedbackRecommends
                          : AppLocalizations.of(context)!.feedbackNotRecommends,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
