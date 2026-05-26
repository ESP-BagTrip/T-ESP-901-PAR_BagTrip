import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/home/widgets/active_trip_weather_card.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter/material.dart';

/// Day badge + weather stack for [ReviewHero.statusBadge] on programme home.
class ActiveTripHeroStatus extends StatelessWidget {
  const ActiveTripHeroStatus({
    super.key,
    required this.currentDay,
    required this.totalDays,
    required this.weather,
    required this.destinationTimezone,
  });

  final int currentDay;
  final int totalDays;
  final WeatherSummary? weather;
  final String? destinationTimezone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            l10n.homeActiveTripDay(currentDay, totalDays),
            style: const TextStyle(
              fontFamily: FontFamily.dMSans,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        ActiveTripWeatherCard(
          weather: weather,
          destinationTimezone: destinationTimezone,
        ),
      ],
    );
  }
}
