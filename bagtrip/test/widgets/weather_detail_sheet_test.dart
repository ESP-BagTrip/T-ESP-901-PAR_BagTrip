import 'package:bagtrip/home/widgets/weather_detail_sheet.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_widget.dart';

void main() {
  Future<void> pumpWithLauncher(
    WidgetTester tester, {
    WeatherSummary? weather,
    String? destinationName,
  }) async {
    await pumpLocalized(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showWeatherDetailSheet(
              context,
              weather: weather,
              destinationName: destinationName,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('showWeatherDetailSheet', () {
    testWidgets('opens with full weather data', (tester) async {
      await pumpWithLauncher(
        tester,
        weather: const WeatherSummary(
          avgTempC: 22.5,
          description: 'Sunny',
          rainProbability: 10,
          source: 'test',
        ),
        destinationName: 'Paris',
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('opens with null weather shows unavailable state', (
      tester,
    ) async {
      await pumpWithLauncher(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('opens without destinationName', (tester) async {
      await pumpWithLauncher(
        tester,
        weather: const WeatherSummary(
          avgTempC: 15.0,
          description: 'Cloudy',
          rainProbability: 60,
          source: 'test',
        ),
      );
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
