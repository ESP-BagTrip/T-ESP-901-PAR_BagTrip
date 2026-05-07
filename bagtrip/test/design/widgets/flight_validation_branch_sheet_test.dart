import 'package:bagtrip/design/widgets/flight_validation_branch_sheet.dart';
import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget mount({
    required VoidCallback onPickExternal,
    required VoidCallback onPickAmadeus,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: FlightValidationBranchSheet(
          onPickExternal: onPickExternal,
          onPickAmadeus: onPickAmadeus,
        ),
      ),
    );
  }

  testWidgets('renders both branches with localised copy', (tester) async {
    await tester.pumpWidget(mount(onPickExternal: () {}, onPickAmadeus: () {}));
    await tester.pump();

    expect(find.text('Validate this flight'), findsOneWidget);
    expect(find.text('I already booked elsewhere'), findsOneWidget);
    expect(find.text('Book through BagTrip'), findsOneWidget);
  });

  testWidgets('tapping the external branch fires onPickExternal', (
    tester,
  ) async {
    var external = 0;
    var amadeus = 0;
    await tester.pumpWidget(
      mount(onPickExternal: () => external++, onPickAmadeus: () => amadeus++),
    );
    await tester.pump();

    await tester.tap(find.text('I already booked elsewhere'));
    await tester.pump();

    expect(external, 1);
    expect(amadeus, 0);
  });

  testWidgets('tapping the Amadeus branch fires onPickAmadeus', (tester) async {
    var external = 0;
    var amadeus = 0;
    await tester.pumpWidget(
      mount(onPickExternal: () => external++, onPickAmadeus: () => amadeus++),
    );
    await tester.pump();

    await tester.tap(find.text('Book through BagTrip'));
    await tester.pump();

    expect(external, 0);
    expect(amadeus, 1);
  });

  testWidgets('FR locale renders French branches', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: FlightValidationBranchSheet(
            onPickExternal: () {},
            onPickAmadeus: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Valider ce vol'), findsOneWidget);
    expect(find.text("J'ai déjà réservé ailleurs"), findsOneWidget);
    expect(find.text('Réserver via BagTrip'), findsOneWidget);
  });
}
