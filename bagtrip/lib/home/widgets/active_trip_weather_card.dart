import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter/material.dart';

/// Read-only weather row under « Voyages & accueil » (no tap, no chevron).
class ActiveTripWeatherCard extends StatelessWidget {
  const ActiveTripWeatherCard({
    super.key,
    required this.weather,
    required this.destinationLabel,
  });

  final WeatherSummary? weather;
  final String destinationLabel;

  static const Color _sunAmber = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dest = destinationLabel.trim();
    final locationLine = _locationSubtitle(
      dest.isNotEmpty ? dest : l10n.tripCardNoDestination,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.large24,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space16,
          vertical: AppSpacing.space12,
        ),
        child: Row(
          children: [
            _WeatherGlyph(weather: weather),
            const SizedBox(width: AppSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weather != null
                        ? '${weather!.avgTempC.round()}°C • ${weather!.description}'
                        : l10n.activeTripWeatherUnavailable,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    locationLine,
                    style: TextStyle(
                      fontFamily: FontFamily.dMSans,
                      fontSize: 12,
                      height: 1.25,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (weather != null) ...[
              const SizedBox(width: AppSpacing.space8),
              Text(
                l10n.activeTripWeatherRainShort(weather!.rainProbability),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: FontFamily.dMSans,
                  fontSize: 11.5,
                  height: 1.25,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Prefer "City • Country" when [raw] contains a comma; keep explicit bullets.
  static String _locationSubtitle(String raw) {
    final t = raw.trim();
    if (t.contains('•')) return t;
    final comma = t.indexOf(',');
    if (comma > 0 && comma < t.length - 1) {
      final a = t.substring(0, comma).trim();
      final b = t.substring(comma + 1).trim();
      if (a.isNotEmpty && b.isNotEmpty) return '$a • $b';
    }
    return t;
  }
}

class _WeatherGlyph extends StatelessWidget {
  const _WeatherGlyph({required this.weather});

  final WeatherSummary? weather;

  @override
  Widget build(BuildContext context) {
    if (weather == null) {
      return Icon(
        Icons.wb_cloudy_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    final d = weather!.description.toLowerCase();
    if (d.contains('rain') ||
        d.contains('pluie') ||
        d.contains('drizzle') ||
        d.contains('shower')) {
      return Icon(
        Icons.umbrella,
        size: 34,
        color: Theme.of(context).colorScheme.primary,
      );
    }
    if (d.contains('snow') || d.contains('neige')) {
      return const Icon(Icons.ac_unit, size: 34, color: Color(0xFF64B5F6));
    }
    if (d.contains('sun') ||
        d.contains('clear') ||
        d.contains('dégagé') ||
        d.contains('degage')) {
      return const Icon(
        Icons.wb_sunny,
        size: 34,
        color: ActiveTripWeatherCard._sunAmber,
      );
    }
    if (d.contains('cloud') || d.contains('nuage') || d.contains('overcast')) {
      return Icon(
        Icons.wb_cloudy,
        size: 36,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return SizedBox(
      width: 40,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.wb_cloudy_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.wb_sunny,
              size: 18,
              color: ActiveTripWeatherCard._sunAmber,
            ),
          ),
        ],
      ),
    );
  }
}
