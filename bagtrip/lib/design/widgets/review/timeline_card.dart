import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Type of event plotted on the overview timeline.
enum TimelineEventType { flight, hotel, activity }

/// A single event on the overview timeline.
class TimelineEvent {
  const TimelineEvent({
    required this.dayOffset,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final int dayOffset;
  final TimelineEventType type;
  final String title;
  final String subtitle;
  final String badge;
}

/// Dot rendered on the timeline rail. Color depends on [type].
class TimelineDot extends StatelessWidget {
  const TimelineDot({super.key, required this.type});

  final TimelineEventType type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      TimelineEventType.flight => ColorName.primaryDark,
      TimelineEventType.hotel => ColorName.primary,
      TimelineEventType.activity => ColorName.secondary,
    };
    final cardSurface = AppColors.reviewCardSurfaceOf(
      Theme.of(context).brightness,
    );
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: cardSurface, width: 2),
      ),
    );
  }
}

/// A card on the overview timeline: vertical rail + colored dot + white card
/// with date label, title and subtitle.
class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.event,
    required this.firstDate,
    this.onTap,
  });

  final TimelineEvent event;
  final DateTime firstDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final date = firstDate.add(Duration(days: event.dayOffset));
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.reviewCardSurfaceOf(brightness),
        borderRadius: AppRadius.large24,
        boxShadow: AppColors.reviewCardShadowOf(brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEE d MMM').format(date).toUpperCase(),
            style: TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondaryOf(brightness),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            event.title,
            style: TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.profileMenuTitleOf(brightness),
            ),
          ),
          if (event.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              event.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                color: AppColors.reviewMutedOf(brightness),
              ),
            ),
          ],
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                height: 18,
                width: 1,
                color: AppColors.reviewDividerOf(brightness),
              ),
              TimelineDot(type: event.type),
              Container(
                height: 74,
                width: 1,
                color: AppColors.reviewDividerOf(brightness),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space16),
            child: onTap == null
                ? card
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.large24,
                      onTap: onTap,
                      child: card,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
