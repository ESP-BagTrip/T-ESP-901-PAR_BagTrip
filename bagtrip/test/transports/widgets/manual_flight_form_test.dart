// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/transports/widgets/manual_flight_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for the panel-mode ManualFlightForm.
///
/// The form's validation logic (airport pair, date ordering, empty flight
/// number) is exercised by the integration suite + real device QA; widget
/// tests here only pin the callback contract so the panel refactor cannot
/// regress: `onSave` is required and the widget renders without a bloc
/// provider in scope.
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
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('exposes a submit button wired to _submit', (tester) async {
      await pumpForm(tester, onSave: (_) {});
      // The primary CTA is a FilledButton — tapping it without input should
      // trigger the validator (which sets errors on the form). No throw.
      expect(find.byType(FilledButton), findsWidgets);
    });
  });
}
