import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter/material.dart';

void showWeatherDetailSheet(
  BuildContext context, {
  required WeatherSummary? weather,
  String? destinationName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _WeatherDetailSheet(weather: weather, destinationName: destinationName),
  );
}

class _WeatherDetailSheet extends StatelessWidget {
  final WeatherSummary? weather;
  final String? destinationName;

  const _WeatherDetailSheet({this.weather, this.destinationName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          Text(
            l10n.weatherSheetTitle,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorName.primary,
            ),
          ),
          if (destinationName != null) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              destinationName!,
              style: TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                color: ColorName.primary.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space24),
          if (weather != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeatherStat(
                  icon: Icons.thermostat_outlined,
                  value: '${weather!.avgTempC.round()}°C',
                  label: l10n.weatherSheetTemperature,
                ),
                _WeatherStat(
                  icon: Icons.water_drop_outlined,
                  value: '${weather!.rainProbability}%',
                  label: l10n.weatherSheetRainProbability,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              weather!.description,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 16,
                color: ColorName.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space24,
              ),
              child: Text(
                l10n.weatherSheetUnavailable,
                style: TextStyle(
                  fontFamily: FontFamily.b612,
                  fontSize: 14,
                  color: ColorName.primary.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpacing.space32),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _WeatherStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: ColorName.primary, size: 28),
        const SizedBox(height: AppSpacing.space4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorName.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          label,
          style: TextStyle(
            fontFamily: FontFamily.b612,
            fontSize: 12,
            color: ColorName.primary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
