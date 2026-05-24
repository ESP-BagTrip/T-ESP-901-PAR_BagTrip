// ignore_for_file: avoid_redundant_argument_values

/// End-to-end coverage of the budget flows through `TripDetailBloc`
/// (topic 09 / SMP-322).
///
/// These tests instantiate the real bloc with mock repositories so the
/// full chain is exercised at the bloc layer :
///   load → BudgetSummary → emit
///   create → optimistic → server failure → rollback (B15)
///   refresh → fail → sectionErrors[budget] (B19)
///   load → role=VIEWER → server-redacted summary surfaces with
///                        budgetStatus bucket only (B9)
///
/// Mobile FT1 / FT3 (`integration_test/`) get the full UI flows in a
/// dedicated session with the `pumpTestApp` harness — these bloc-level
/// tests pin the contract so a regression on any topic
/// (02 / 03 / 04b / 06) breaks fast and loud without paying the
/// integration_test setup cost.
library;

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class _MockTripRepository extends Mock implements TripRepository {}

class _MockActivityRepository extends Mock implements ActivityRepository {}

class _MockAccommodationRepository extends Mock
    implements AccommodationRepository {}

class _MockBaggageRepository extends Mock implements BaggageRepository {}

class _MockBudgetRepository extends Mock implements BudgetRepository {}

class _MockTransportRepository extends Mock implements TransportRepository {}

class _MockTripShareRepository extends Mock implements TripShareRepository {}

void _stubAllSuccess({
  required _MockTripRepository trip,
  required _MockActivityRepository activity,
  required _MockAccommodationRepository accommodation,
  required _MockBaggageRepository baggage,
  required _MockBudgetRepository budget,
  required _MockTransportRepository transport,
  required _MockTripShareRepository share,
  required String tripId,
  required BudgetSummary summary,
  required List<BudgetItem> items,
}) {
  when(
    () => trip.getTripById(any()),
  ).thenAnswer((_) async => Success(makeTrip(id: tripId)));
  when(
    () => activity.getActivities(any()),
  ).thenAnswer((_) async => const Success([]));
  when(
    () => accommodation.getByTrip(any()),
  ).thenAnswer((_) async => const Success(<Accommodation>[]));
  when(
    () => baggage.getByTrip(any()),
  ).thenAnswer((_) async => const Success(<BaggageItem>[]));
  when(
    () => transport.getManualFlights(any()),
  ).thenAnswer((_) async => const Success(<ManualFlight>[]));
  when(
    () => share.getSharesByTrip(any()),
  ).thenAnswer((_) async => const Success(<TripShare>[]));
  when(
    () => budget.getBudgetSummary(any()),
  ).thenAnswer((_) async => Success(summary));
  when(
    () => budget.getBudgetItems(any()),
  ).thenAnswer((_) async => Success(items));
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late _MockTripRepository tripRepo;
  late _MockActivityRepository activityRepo;
  late _MockAccommodationRepository accommodationRepo;
  late _MockBaggageRepository baggageRepo;
  late _MockBudgetRepository budgetRepo;
  late _MockTransportRepository transportRepo;
  late _MockTripShareRepository shareRepo;

  setUp(() {
    tripRepo = _MockTripRepository();
    activityRepo = _MockActivityRepository();
    accommodationRepo = _MockAccommodationRepository();
    baggageRepo = _MockBaggageRepository();
    budgetRepo = _MockBudgetRepository();
    transportRepo = _MockTransportRepository();
    shareRepo = _MockTripShareRepository();
  });

  TripDetailBloc buildBloc() => TripDetailBloc(
    tripRepository: tripRepo,
    activityRepository: activityRepo,
    accommodationRepository: accommodationRepo,
    baggageRepository: baggageRepo,
    budgetRepository: budgetRepo,
    transportRepository: transportRepo,
    tripShareRepository: shareRepo,
  );

  group('budget E2E — viewer redaction (topics 06 + 02)', () {
    test(
      'viewer_cannot_see_amounts: server-redacted summary surfaces budgetStatus only',
      () async {
        // Server-side redaction (commit 176b4a96) ships these zeros for
        // VIEWER. Bloc must propagate them as-is so the panel never has
        // to reconstruct anything.
        _stubAllSuccess(
          trip: tripRepo,
          activity: activityRepo,
          accommodation: accommodationRepo,
          baggage: baggageRepo,
          budget: budgetRepo,
          transport: transportRepo,
          share: shareRepo,
          tripId: 'trip-viewer',
          summary: const BudgetSummary(
            totalBudget: 1500,
            totalSpent: 0,
            remaining: 0,
            confirmedTotal: 0,
            forecastedTotal: 0,
            budgetStatus: 'tight',
          ),
          items: const [],
        );

        final bloc = buildBloc();
        bloc.add(LoadTripDetail(tripId: 'trip-viewer'));
        await Future<void>.delayed(const Duration(milliseconds: 300));

        final loaded = bloc.state as TripDetailLoaded;
        expect(loaded.budgetSummary?.budgetStatus, 'tight');
        // Reconstructible amounts must already be zeroed by the server.
        expect(loaded.budgetSummary?.totalSpent, 0);
        expect(loaded.budgetSummary?.confirmedTotal, 0);
        expect(loaded.budgetSummary?.forecastedTotal, 0);

        await bloc.close();
      },
    );
  });

  group('budget E2E — optimistic rollback (topic 03 B15)', () {
    test(
      'budget_optimistic_rollback_on_network_error: pre-optimistic state restored',
      () async {
        _stubAllSuccess(
          trip: tripRepo,
          activity: activityRepo,
          accommodation: accommodationRepo,
          baggage: baggageRepo,
          budget: budgetRepo,
          transport: transportRepo,
          share: shareRepo,
          tripId: 'trip-rb',
          summary: const BudgetSummary(
            totalBudget: 1000,
            totalSpent: 200,
            remaining: 800,
            confirmedTotal: 200,
          ),
          items: const [],
        );

        when(
          () => budgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));

        final bloc = buildBloc();
        bloc.add(LoadTripDetail(tripId: 'trip-rb'));
        await Future<void>.delayed(const Duration(milliseconds: 300));

        // Sanity check: pre-optimistic state.
        expect((bloc.state as TripDetailLoaded).budgetSummary?.remaining, 800);

        bloc.add(
          CreateBudgetItemFromDetail(data: {'amount': 50, 'label': 'Taxi'}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // After rollback + clearOperationError emit cycle.
        final loaded = bloc.state as TripDetailLoaded;
        expect(loaded.budgetSummary?.totalSpent, 200);
        expect(loaded.budgetSummary?.remaining, 800);
        expect(loaded.operationError, isNull);

        await bloc.close();
      },
    );
  });

  group('budget E2E — refresh failure surfaces (topic 08 B19)', () {
    test(
      'failed RefreshBudgetSummary populates sectionErrors[budget]',
      () async {
        _stubAllSuccess(
          trip: tripRepo,
          activity: activityRepo,
          accommodation: accommodationRepo,
          baggage: baggageRepo,
          budget: budgetRepo,
          transport: transportRepo,
          share: shareRepo,
          tripId: 'trip-ref',
          summary: const BudgetSummary(totalBudget: 500),
          items: const [],
        );

        final bloc = buildBloc();
        bloc.add(LoadTripDetail(tripId: 'trip-ref'));
        await Future<void>.delayed(const Duration(milliseconds: 300));

        // Now make subsequent fetches fail.
        when(
          () => budgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => const Failure(ServerError('boom')));
        when(
          () => budgetRepo.getBudgetItems(any()),
        ).thenAnswer((_) async => const Failure(ServerError('boom')));

        bloc.add(RefreshBudgetSummaryFromDetail());
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Topic 08 B19 — sectionErrors['budget'] surfaces the failure
        // instead of the panel staying silent.
        final loaded = bloc.state as TripDetailLoaded;
        expect(loaded.sectionErrors['budget'], isNotNull);

        await bloc.close();
      },
    );
  });
}
