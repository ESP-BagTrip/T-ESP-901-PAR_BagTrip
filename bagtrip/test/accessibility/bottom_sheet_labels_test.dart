// ignore_for_file: avoid_redundant_argument_values
import 'package:bagtrip/design/widgets/item_form_scaffold.dart';
import 'package:bagtrip/home/widgets/weather_detail_sheet.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'a11y_test_helpers.dart';

/// Finds a [Semantics] container node carrying the given [label].
Finder _containerLabel(String label) {
  return find.byWidgetPredicate(
    (w) => w is Semantics && w.container && w.properties.label == label,
  );
}

void main() {
  group('AX1 — Bottom sheet labels (SMP327-044)', () {
    testWidgets('ItemFormScaffold wraps content in a labelled container', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ItemFormScaffold(
            title: 'Edit flight',
            fields: SizedBox.shrink(),
            actions: [],
          ),
        ),
      );
      await tester.pump();

      expect(_containerLabel('Edit flight'), findsOneWidget);
    });

    testWidgets('weather detail sheet announces its title on open', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showWeatherDetailSheet(
                context,
                weather: const WeatherSummary(
                  avgTempC: 21,
                  description: 'Sunny',
                  rainProbability: 10,
                ),
                destinationName: 'Paris',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // "Weather" = l10n.weatherSheetTitle (en).
      expect(_containerLabel('Weather'), findsOneWidget);
    });
  });
}
