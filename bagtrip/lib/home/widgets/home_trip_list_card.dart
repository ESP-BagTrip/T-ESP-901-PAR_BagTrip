import 'package:bagtrip/design/app_haptics.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/navigation/route_definitions.dart';
import 'package:flutter/material.dart';

class HomeTripListSection extends StatelessWidget {
  final String title;
  final List<Trip> trips;

  const HomeTripListSection({
    super.key,
    required this.title,
    required this.trips,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: FontFamily.dMSans,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorName.primaryTrueDark,
          ),
        ),
        const SizedBox(height: AppSpacing.space12),
        ...trips.map(
          (trip) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space12),
            child: HomeTripListCard(trip: trip),
          ),
        ),
      ],
    );
  }
}

class HomeTripListCard extends StatelessWidget {
  final Trip trip;

  const HomeTripListCard({super.key, required this.trip});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'janv.',
      'fevr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'aout',
      'sept.',
      'oct.',
      'nov.',
      'dec.',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _dateRange() {
    final start = _formatDate(trip.startDate);
    final end = _formatDate(trip.endDate);
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  String _deadlineLabel(AppLocalizations l10n) {
    if (trip.status == TripStatus.ongoing) return l10n.tripStatusOngoing;
    final start = trip.startDate;
    if (start == null) return l10n.tripStatusPlanned;
    final now = DateTime.now();
    final days = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= 0) return l10n.timelineNow;
    return l10n.nextTripCountdown(days);
  }

  int? _daysUntilStart() {
    final start = trip.startDate;
    if (start == null) return null;
    final now = DateTime.now();
    return DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  Color _leftBorderColor() {
    final days = _daysUntilStart();
    if (days != null && days >= 1 && days <= 7) {
      return ColorName.secondary;
    }
    return const Color(0xFFD4A853);
  }

  Color _temporalAccentColor() => _leftBorderColor();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destination =
        trip.destinationName ?? trip.title ?? l10n.myTripFallback;
    final progress = tripCompletion(trip).clamp(0, 100);
    final accentColor = _temporalAccentColor();

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.large24,
        boxShadow: [
          BoxShadow(
            color: Color(0x140E1A2B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.large24,
          onTap: () {
            AppHaptics.light();
            TripHomeRoute(tripId: trip.id).push(context);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: ColorName.surface,
              borderRadius: AppRadius.large24,
              border: Border.all(color: ColorName.primarySoftLight),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.large24,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 6, color: _leftBorderColor()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: FontFamily.dMSerifDisplay,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w400,
                                  color: ColorName.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space12,
                                vertical: AppSpacing.space8,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.14),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                _deadlineLabel(l10n),
                                style: TextStyle(
                                  fontFamily: FontFamily.dMSans,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Text(
                          _dateRange(),
                          style: const TextStyle(
                            fontFamily: FontFamily.dMSans,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ColorName.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space16),
                        ClipRRect(
                          borderRadius: AppRadius.small4,
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 7,
                            backgroundColor: ColorName.primarySoftLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            l10n.homeTripValidatedProgress(progress),
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorName.textMutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space16,
                            vertical: AppSpacing.space12,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: AppRadius.large16,
                          ),
                          child: Text(
                            trip.status == TripStatus.ongoing
                                ? l10n.homeResumeActiveTripCta
                                : l10n.homeCtaStartPlanning,
                            style: const TextStyle(
                              fontFamily: FontFamily.dMSans,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ColorName.surface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
