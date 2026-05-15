import 'package:bagtrip/l10n/app_localizations.dart';
import 'package:bagtrip/trip_detail/view/panels/trip_panel_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    DateTime? tripStartDate,
    bool canEdit = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: TripPanelEmptyState(
            icon: Icons.flight_takeoff_rounded,
            title: 'Vous n\'avez pas de vol enregistré',
            ctaLabel: 'Ajouter maintenant',
            tripStartDate: tripStartDate,
            canEdit: canEdit,
            onCta: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows countdown line when departure is in the future', (
    tester,
  ) async {
    final start = DateTime.now().add(const Duration(days: 10));
    await pump(tester, tripStartDate: start);
    expect(find.textContaining('10 jours'), findsOneWidget);
  });
}
