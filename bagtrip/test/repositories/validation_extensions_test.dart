// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart' show Activity, ActivityCategory;
import 'package:bagtrip/models/budget_item.dart'
    show BudgetItem, BudgetCategory;
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/validation_status.dart';
import 'package:bagtrip/repositories/validation_extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('validation_extensions', () {
    test(
      'ActivityRepository.validate PATCHes validationStatus=VALIDATED',
      () async {
        final repo = MockActivityRepository();
        const activity = Activity(
          id: 'a1',
          tripId: 't1',
          title: 'Sagrada',
          category: ActivityCategory.culture,
          validationStatus: ValidationStatus.validated,
        );
        when(
          () => repo.updateActivity('t1', 'a1', any()),
        ).thenAnswer((_) async => const Success(activity));

        final result = await repo.validate('t1', 'a1');

        expect(result, isA<Success<Activity>>());
        final captured = verify(
          () => repo.updateActivity('t1', 'a1', captureAny()),
        ).captured.single;
        // The bloc + extensions speak to the backend in camelCase, which
        // is the convention of every modern client call site.
        expect(captured, {'validationStatus': 'VALIDATED'});
      },
    );

    test(
      'TransportRepository.validate PATCHes validationStatus=VALIDATED',
      () async {
        final repo = MockTransportRepository();
        const flight = ManualFlight(
          id: 'f1',
          tripId: 't1',
          flightNumber: 'AF1234',
          flightType: 'MAIN',
          validationStatus: ValidationStatus.validated,
        );
        when(
          () => repo.updateManualFlight('t1', 'f1', any()),
        ).thenAnswer((_) async => const Success(flight));

        final result = await repo.validate('t1', 'f1');

        expect(result, isA<Success<ManualFlight>>());
        final captured = verify(
          () => repo.updateManualFlight('t1', 'f1', captureAny()),
        ).captured.single;
        expect(captured, {'validationStatus': 'VALIDATED'});
      },
    );

    test(
      'AccommodationRepository.validate PATCHes validationStatus=VALIDATED',
      () async {
        final repo = MockAccommodationRepository();
        const acc = Accommodation(
          id: 'h1',
          tripId: 't1',
          name: 'Hotel Tokyo',
          validationStatus: ValidationStatus.validated,
        );
        when(
          () => repo.updateAccommodation('t1', 'h1', any()),
        ).thenAnswer((_) async => const Success(acc));

        final result = await repo.validate('t1', 'h1');

        expect(result, isA<Success<Accommodation>>());
        final captured = verify(
          () => repo.updateAccommodation('t1', 'h1', captureAny()),
        ).captured.single;
        expect(captured, {'validationStatus': 'VALIDATED'});
      },
    );

    test(
      'BudgetRepository.validate PATCHes validationStatus=VALIDATED',
      () async {
        final repo = MockBudgetRepository();
        const item = BudgetItem(
          id: 'b1',
          tripId: 't1',
          label: 'JR Pass',
          amount: 240,
          category: BudgetCategory.transport,
          validationStatus: ValidationStatus.validated,
        );
        when(
          () => repo.updateBudgetItem('t1', 'b1', any()),
        ).thenAnswer((_) async => const Success(item));

        final result = await repo.validate('t1', 'b1');

        expect(result, isA<Success<BudgetItem>>());
        final captured = verify(
          () => repo.updateBudgetItem('t1', 'b1', captureAny()),
        ).captured.single;
        expect(captured, {'validationStatus': 'VALIDATED'});
      },
    );
  });
}
