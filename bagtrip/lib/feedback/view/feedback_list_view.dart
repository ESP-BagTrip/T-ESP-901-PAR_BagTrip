import 'package:bagtrip/components/empty_state.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeedbackListView extends StatelessWidget {
  final List<TripFeedback> feedbacks;

  const FeedbackListView({super.key, required this.feedbacks});

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Aucun avis',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        color: Colors.amber,
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
                  const SizedBox(height: 8),
                  Text(
                    'Points forts : ${feedback.highlights}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (feedback.lowlights != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '\u00c0 am\u00e9liorer : ${feedback.lowlights}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      feedback.wouldRecommend
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      size: 16,
                      color: feedback.wouldRecommend
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      feedback.wouldRecommend
                          ? 'Recommande'
                          : 'Ne recommande pas',
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
