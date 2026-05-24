import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/utils/destination_time.dart';
import 'package:flutter/material.dart';

/// Semi-transparent weather pill for the active trip hero (condition icon + min–max).
///
/// Night icon when destination local hour is before 6 or from 20:00 onward
/// ([nowInDestination]).
class ActiveTripWeatherCard extends StatelessWidget {
  const ActiveTripWeatherCard({
    super.key,
    required this.weather,
    required this.destinationTimezone,
  });

  /// Stable finder target for widget tests.
  static const ValueKey<String> heroWeatherKey = ValueKey<String>(
    'activeTripHeroWeather',
  );

  final WeatherSummary? weather;
  final String? destinationTimezone;

  static const Color _sunAmber = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: AppRadius.large16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          borderRadius: AppRadius.large16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            key: heroWeatherKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroWeatherGlyph(
                weather: weather,
                destinationTimezone: destinationTimezone,
                sunAmber: _sunAmber,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                weather != null
                    ? _temperatureLine(weather!)
                    : l10n.activeTripWeatherUnavailable,
                style: const TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _temperatureLine(WeatherSummary w) {
    final min = (w.minTempC ?? w.avgTempC).round();
    final max = (w.maxTempC ?? w.avgTempC).round();
    return '$min°C – $max°C';
  }
}

class _HeroWeatherGlyph extends StatelessWidget {
  const _HeroWeatherGlyph({
    required this.weather,
    required this.destinationTimezone,
    required this.sunAmber,
  });

  final WeatherSummary? weather;
  final String? destinationTimezone;
  final Color sunAmber;

  /// Local "night" for icon choice (destination clock).
  static bool _isLocalNight(DateTime local) =>
      local.hour < 6 || local.hour >= 20;

  static bool _wind(String d) =>
      d.contains('wind') ||
      d.contains('vent') ||
      d.contains('gust') ||
      d.contains('storm') ||
      d.contains('tempête') ||
      d.contains('tempete');

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return Icon(
        Icons.wb_cloudy_outlined,
        size: 22,
        color: Colors.white.withValues(alpha: 0.85),
      );
    }

    final local = nowInDestination(destinationTimezone);
    if (_isLocalNight(local)) {
      return Icon(
        Icons.nightlight_round,
        size: 22,
        color: Colors.white.withValues(alpha: 0.9),
      );
    }

    final d = weather!.description.toLowerCase();
    if (d.contains('rain') ||
        d.contains('pluie') ||
        d.contains('drizzle') ||
        d.contains('shower')) {
      return Icon(
        Icons.umbrella,
        size: 22,
        color: Colors.white.withValues(alpha: 0.95),
      );
    }
    if (d.contains('snow') || d.contains('neige')) {
      return Icon(
        Icons.ac_unit,
        size: 22,
        color: Colors.white.withValues(alpha: 0.95),
      );
    }
    if (_wind(d)) {
      return Icon(
        Icons.air,
        size: 22,
        color: Colors.white.withValues(alpha: 0.9),
      );
    }
    if (d.contains('clear') ||
        d.contains('sun') ||
        d.contains('dégagé') ||
        d.contains('degage') ||
        d.contains('pleasant') ||
        d.contains('hot') ||
        d.contains('warm')) {
      return Icon(Icons.wb_sunny, size: 22, color: sunAmber);
    }
    if (d.contains('cloud') ||
        d.contains('nuage') ||
        d.contains('overcast') ||
        d.contains('cool')) {
      return Icon(
        Icons.wb_cloudy,
        size: 22,
        color: Colors.white.withValues(alpha: 0.9),
      );
    }
    return SizedBox(
      width: 28,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.wb_cloudy_outlined,
            size: 22,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          Positioned(
            top: -2,
            right: -4,
            child: Icon(Icons.wb_sunny, size: 14, color: sunAmber),
          ),
        ],
      ),
    );
  }
}
