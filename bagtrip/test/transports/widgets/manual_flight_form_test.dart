// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/design/widgets/form/form_section_header.dart';
import 'package:bagtrip/design/widgets/form/item_form_primary_button.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for the panel-mode ManualFlightForm.
Future<void> pumpForm(
  WidgetTester tester, {
  required void Function(Map<String, dynamic>) onSave,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ManualFlightForm(tripId: 'trip-1', onSave: onSave),
        ),
      ),
    ),
  );
}

void main() {
  group('ManualFlightForm', () {
    testWidgets('renders without a TransportBloc provider (panel mode)', (
      tester,
    ) async {
      await pumpForm(tester, onSave: (_) {});
      expect(find.byType(ManualFlightForm), findsOneWidget);
      expect(find.byType(FormSectionHeader), findsNWidgets(3));
    });

    testWidgets('uses addFlight title and secondary CTA in create mode', (
      tester,
    ) async {
      await pumpForm(tester, onSave: (_) {});
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(find.text(l10n.addFlight), findsWidgets);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), ColorName.secondary);
    });

    testWidgets('exposes a primary CTA button', (tester) async {
      await pumpForm(tester, onSave: (_) {});
      expect(find.byType(ItemFormPrimaryButton), findsOneWidget);
    });
  });
}
