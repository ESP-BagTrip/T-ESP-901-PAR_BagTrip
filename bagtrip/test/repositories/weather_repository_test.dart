import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeatherSummary', () {
    test('fromJson parses correctly', () {
      final json = {
        'avg_temp_c': 22.5,
        'description': 'Warm and pleasant',
        'rain_probability': 15,
        'source': 'open-meteo',
      };

      final summary = WeatherSummary.fromJson(json);

      expect(summary.avgTempC, 22.5);
      expect(summary.description, 'Warm and pleasant');
      expect(summary.rainProbability, 15);
      expect(summary.source, 'open-meteo');
    });

    test('fromJson with defaults', () {
      final json = {'avg_temp_c': 20.0, 'description': 'Mild'};

      final summary = WeatherSummary.fromJson(json);

      expect(summary.avgTempC, 20.0);
      expect(summary.rainProbability, 0);
      expect(summary.source, 'unknown');
    });

    test('toJson roundtrip', () {
      const summary = WeatherSummary(
        avgTempC: 25.0,
        description: 'Sunny',
        rainProbability: 10,
        source: 'test',
      );

      final json = summary.toJson();
      final restored = WeatherSummary.fromJson(json);

      expect(restored.avgTempC, summary.avgTempC);
      expect(restored.minTempC, summary.minTempC);
      expect(restored.maxTempC, summary.maxTempC);
      expect(restored.description, summary.description);
      expect(restored.rainProbability, summary.rainProbability);
      expect(restored.source, summary.source);
    });
  });
}
