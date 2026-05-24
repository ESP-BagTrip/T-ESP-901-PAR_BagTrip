import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/review_inline_flight.dart';
import 'package:bagtrip/design/widgets/review/review_inline_hotel.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Single activity row inside a day — pure textual note, no iconography.
class ReviewDayActivity {
  const ReviewDayActivity({required this.title, this.description = ''});
  final String title;
  final String description;
}

/// Everything the day card needs. [flights] and [hotelArrival] surface
/// inline when they belong to this day.
class ReviewDayCardData {
  const ReviewDayCardData({
    required this.dayNumber,
    required this.dateLabel,
    required this.flights,
    required this.hotelArrival,
    required this.activities,
  });

  final int dayNumber;
  final String dateLabel;
  final List<ReviewInlineFlightData> flights;
  final ReviewInlineHotelData? hotelArrival;
  final List<ReviewDayActivity> activities;

  bool get isEmpty =>
      flights.isEmpty && hotelArrival == null && activities.isEmpty;
}

/// One day rendered as a soft paper card — large serif day number, a
/// hairline rule, the date in small caps, then events.
class ReviewDayCard extends StatelessWidget {
  const ReviewDayCard({
    super.key,
    required this.data,
    required this.freeDayLabel,
    required this.dayTitle,
  });

  final ReviewDayCardData data;
  final String freeDayLabel;

  /// Pre-formatted date ("Mon 12 Apr"). The number lives in [data.dayNumber].
  final String dayTitle;

  @override
  Widget build(BuildContext context) {
    final events = <Widget>[];
    for (final flight in data.flights) {
      events.add(ReviewInlineFlight(data: flight));
      events.add(const SizedBox(height: AppSpacing.space12));
    }
    if (data.hotelArrival != null) {
      events.add(ReviewInlineHotel(data: data.hotelArrival!));
      events.add(const SizedBox(height: AppSpacing.space12));
    }
    for (var i = 0; i < data.activities.length; i++) {
      events.add(_ActivityRow(activity: data.activities[i]));
      if (i < data.activities.length - 1) {
        events.add(const SizedBox(height: AppSpacing.space4));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.large24,
          border: Border.all(color: AppColors.reviewBorderLight, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(dayNumber: data.dayNumber, dateLabel: dayTitle),
              const SizedBox(height: AppSpacing.space24),
              if (events.isEmpty)
                _FreeDayNote(label: freeDayLabel)
              else
                ...events,
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.dayNumber, required this.dateLabel});

  final int dayNumber;

  /// Already formatted date label (e.g. "Mon 12 Apr").
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          dayNumber.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: FontFamily.dMSerifDisplay,
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            color: AppColors.reviewInk,
          ),
        ),
        const SizedBox(width: AppSpacing.space16),
        Container(
          width: 24,
          height: 1,
          color: AppColors.reviewInk.withValues(alpha: 0.25),
        ),
        const SizedBox(width: AppSpacing.space16),
        Expanded(
          child: Text(
            dateLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: AppColors.reviewInk.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ReviewDayActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 28,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: AppColors.reviewInk.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                    color: AppColors.reviewInk,
                  ),
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: AppColors.reviewSubtle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeDayNote extends StatelessWidget {
  const _FreeDayNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: FontFamily.dMSerifDisplay,
        fontSize: 16,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        color: AppColors.reviewInk.withValues(alpha: 0.45),
      ),
    );
  }
}
