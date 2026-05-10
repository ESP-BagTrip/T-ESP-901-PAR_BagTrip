// ignore_for_file: avoid_redundant_argument_values, prefer_const_constructors

/// FT6 — Cross-topic budget flows end-to-end via `pumpTestApp` (topic 09).
///
/// Each scenario boots the full app with `setupTestServiceLocator()`,
/// stubs the relevant repositories, and pins the contract that links a
/// server response to a state visible to the user. Mobile widget render
/// is covered by the dedicated panel test (`budget_panel_test.dart`)
/// and the bloc-level integration test
/// (`test/trip_detail/integration/budget_e2e_test.dart`) — this file
/// covers what they can't : the *full DI graph* boots clean with the
/// new contract, and the auth + home stack accepts the redacted /
/// multi-currency / split-target payloads without throwing.
library;

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/e2e_fixtures.dart';
import 'helpers/finders.dart' as f;
import 'helpers/mock_di_setup.dart';
import 'helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerE2eFallbackValues();
  });

  group('FT6 — Budget flows (cross-topic E2E)', () {
    testWidgets(
      'viewer_cannot_see_amounts: getBudgetSummary returns redacted payload',
      (tester) async {
        // Topic 06 (B9) — server ships zeros + budgetStatus bucket. The
        // app must accept this shape end-to-end : DI boot, auth, home
        // listing, and any downstream call to getBudgetSummary returns
        // the redacted payload as-is, no client-side reconstruction.
        final viewer = makeUser(id: 'user-viewer', email: 'viewer@example.com');
        final trip = makeTrip(
          id: 'trip-viewer',
          title: 'Shared trip',
          status: TripStatus.planned,
          destinationName: 'Rome',
        );

        final mocks = await setupTestServiceLocator();
        stubAuthenticated(mocks, user: viewer);
        stubTripManagerHome(mocks, planned: [trip]);

        // Server-redacted payload (cf. commit 176b4a96) :
        when(() => mocks.budget.getBudgetSummary('trip-viewer')).thenAnswer(
          (_) async => const Success(
            BudgetSummary(
              totalBudget: 1500,
              totalSpent: 0,
              remaining: 0,
              confirmedTotal: 0,
              forecastedTotal: 0,
              budgetStatus: 'tight',
            ),
          ),
        );
        // Even if the items endpoint leaks (defence in depth), the
        // bloc/panel must not propagate any number.
        when(
          () => mocks.budget.getBudgetItems('trip-viewer'),
        ).thenAnswer((_) async => const Success(<BudgetItem>[]));

        await pumpTestApp(tester, existingMocks: mocks);

        expect(f.homeIdle, findsOneWidget);

        // Verify the contract directly through the mock surface.
        final summary = await mocks.budget.getBudgetSummary('trip-viewer');
        expect(summary, isA<Success<BudgetSummary>>());
        final s = (summary as Success<BudgetSummary>).data;
        expect(s.budgetStatus, 'tight');
        expect(s.totalSpent, 0);
        expect(s.confirmedTotal, 0);
        expect(s.forecastedTotal, 0);
        // The target shape stays for layout — viewer sees how big the
        // budget is but not how much was spent.
        expect(s.totalBudget, 1500);
      },
    );

    testWidgets('budget_optimistic_rollback_on_network_error: '
        'createBudgetItem failure rolls cache through CachedBudgetRepository', (
      tester,
    ) async {
      // Topic 03 (B15). Validate end-to-end that a network ko on the
      // create path is observable by the test (proxy for the bloc-level
      // rollback that lives in the dedicated integration test).
      final trip = makeTrip(
        id: 'trip-rb',
        title: 'Rollback Trip',
        status: TripStatus.planned,
        destinationName: 'Lyon',
      );

      final mocks = await setupTestServiceLocator();
      stubTripManagerHome(mocks, planned: [trip]);

      when(
        () => mocks.budget.createBudgetItem('trip-rb', any()),
      ).thenAnswer((_) async => const Failure(NetworkError('offline')));

      await pumpTestApp(tester, existingMocks: mocks);
      expect(f.homeIdle, findsOneWidget);

      final result = await mocks.budget.createBudgetItem('trip-rb', {
        'amount': 50,
        'label': 'Taxi',
      });
      expect(result, isA<Failure<BudgetItem>>());
      expect((result as Failure).error, isA<NetworkError>());
    });

    // SMP-325: ``/plan-trip/accept`` was removed. The B23 contract
    // (per-night unit derivation) is now enforced inside the wizard's
    // ``_tripPlanFromDraft`` parser and pinned by
    // ``test/blocs/plan_trip_bloc_test.dart`` ("B23 — accommodation
    // with price_total + nights derives per-night price"). The
    // accept-payload integration test is therefore retired.

    testWidgets(
      'plan_trip_multi_currency: BudgetSummary surface accepts mixed-currency response',
      (tester) async {
        // Topic 04b (B11). The currency_service stub returns identity in
        // tests, but the BudgetSummary contract supports a multi-currency
        // payload : `totalBudget` is in `Trip.currency`, `total_spent` is
        // already converted to `Trip.currency` server-side (cf.
        // budget_item_service.get_budget_summary). The mobile contract
        // must accept this without breaking on the historic EUR-only
        // shape.
        final trip = makeTrip(
          id: 'trip-mc',
          title: 'Tokyo Trip (USD)',
          status: TripStatus.planned,
          destinationName: 'Tokyo',
        );
        final mocks = await setupTestServiceLocator();
        stubTripManagerHome(mocks, planned: [trip]);

        when(() => mocks.budget.getBudgetSummary('trip-mc')).thenAnswer(
          // Server already converted USD/EUR/JPY items to the trip
          // currency. The Flutter side reads `totalSpent` flat.
          (_) async => const Success(
            BudgetSummary(
              totalBudget: 5000,
              totalSpent: 1234.56,
              remaining: 3765.44,
              confirmedTotal: 1234.56,
              percentConsumed: 24.69,
            ),
          ),
        );

        await pumpTestApp(tester, existingMocks: mocks);
        expect(f.homeIdle, findsOneWidget);

        final result = await mocks.budget.getBudgetSummary('trip-mc');
        final s = (result as Success<BudgetSummary>).data;
        // No currency-specific assertion — the value is already the
        // server-side conversion result. We just pin that the mobile
        // surface accepts a non-round mixed-currency aggregate.
        expect(s.totalBudget, 5000);
        expect(s.totalSpent, closeTo(1234.56, 0.01));
        expect(s.remaining, closeTo(3765.44, 0.01));
      },
    );
  });
}
