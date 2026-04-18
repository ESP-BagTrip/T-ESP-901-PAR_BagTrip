import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/design/widgets/review/review_inline_flight.dart';
import 'package:bagtrip/design/widgets/review/review_inline_hotel.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Single activity row inside a day. Simpler than ActivityTile (no category
/// pill, no emoji thumbnail) — the day card is the visual anchor, activities
/// are textual notes.
class ReviewDayActivity {
  const ReviewDayActivity({required this.title, this.description = ''});
  final String title;
  final String description;
}

/// Everything the day card needs to render. [flights] and [hotelArrival]
/// surface automatically when non-null, preserving the day's narrative order
/// (flights first, then check-in, then activities).
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

/// Single day rendered as a raised card. A bold day chip anchors the upper
/// edge, events stack inside with clear vertical rhythm.
class ReviewDayCard extends StatelessWidget {
  const ReviewDayCard({
    super.key,
    required this.data,
    required this.freeDayLabel,
    required this.dayTitle,
  });

  final ReviewDayCardData data;
  final String freeDayLabel;

  /// Pre-formatted day title ("Day 1 · Mon 12 Apr").
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
        events.add(const SizedBox(height: AppSpacing.space8));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.large24,
          boxShadow: [
            BoxShadow(
              color: ColorName.primaryDark.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DayHeader(dayNumber: data.dayNumber, title: dayTitle),
              const SizedBox(height: AppSpacing.space16),
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
  const _DayHeader({required this.dayNumber, required this.title});

  final int dayNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorName.primaryDark, Color(0xFF1B3A5E)],
            ),
            borderRadius: AppRadius.large16,
            boxShadow: [
              BoxShadow(
                color: ColorName.primaryDark.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'D$dayNumber',
            style: const TextStyle(
              fontFamily: FontFamily.dMSerifDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.reviewInk,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: ColorName.secondary.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontFamily: FontFamily.dMSerifDisplay,
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                    color: AppColors.reviewInk,
                  ),
                ),
                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 13,
                      height: 1.4,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: FontFamily.dMSans,
          fontSize: 13,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          color: AppColors.reviewFaint,
        ),
      ),
    );
  }
}
