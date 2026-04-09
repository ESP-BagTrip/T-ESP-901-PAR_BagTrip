import 'package:bagtrip/budget/bloc/budget_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockBudgetRepository mockBudgetRepo;

  setUp(() {
    mockBudgetRepo = MockBudgetRepository();
  });

  /// Helper to stub both getBudgetItems and getBudgetSummary for success.
  void stubLoadBudgetSuccess() {
    when(
      () => mockBudgetRepo.getBudgetItems(any()),
    ).thenAnswer((_) async => Success([makeBudgetItem()]));
    when(
      () => mockBudgetRepo.getBudgetSummary(any()),
    ).thenAnswer((_) async => Success(makeBudgetSummary()));
  }

  group('BudgetBloc', () {
    // ── LoadBudget ──────────────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when LoadBudget succeeds',
      build: () {
        stubLoadBudgetSuccess();
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(LoadBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetLoading>(), isA<BudgetLoaded>()],
      verify: (bloc) {
        verify(() => mockBudgetRepo.getBudgetItems('trip-1')).called(1);
        verify(() => mockBudgetRepo.getBudgetSummary('trip-1')).called(1);
        final state = bloc.state as BudgetLoaded;
        expect(state.items.length, 1);
        expect(state.summary.totalBudget, 1000);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetError] when getBudgetItems fails',
      build: () {
        when(
          () => mockBudgetRepo.getBudgetItems(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary()));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(LoadBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetLoading>(), isA<BudgetError>()],
    );

    // ── CreateBudgetItem ────────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'CreateBudgetItem appends item and refreshes summary',
      build: () {
        final newItem = makeBudgetItem(id: 'budget-new', label: 'Taxi');
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => Success(newItem));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary(totalSpent: 520)));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      seed: () =>
          BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
      act: (bloc) => bloc.add(
        CreateBudgetItem(
          tripId: 'trip-1',
          data: {'label': 'Taxi', 'amount': 30.0},
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoaded>(), isA<BudgetLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BudgetLoaded;
        expect(state.items.length, 2);
        expect(state.items.last.id, 'budget-new');
        expect(state.summary.totalSpent, 520);
        verify(() => mockBudgetRepo.getBudgetSummary('trip-1')).called(1);
        verifyNever(() => mockBudgetRepo.getBudgetItems(any()));
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'CreateBudgetItem falls back to LoadBudget when state is not BudgetLoaded',
      build: () {
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => Success(makeBudgetItem()));
        stubLoadBudgetSuccess();
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(
        CreateBudgetItem(
          tripId: 'trip-1',
          data: {'label': 'Taxi', 'amount': 30.0},
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoading>(), isA<BudgetLoaded>()],
    );

    blocTest<BudgetBloc, BudgetState>(
      'CreateBudgetItem keeps stale summary when summary refresh fails',
      build: () {
        when(() => mockBudgetRepo.createBudgetItem(any(), any())).thenAnswer(
          (_) async => Success(makeBudgetItem(id: 'budget-new', label: 'Taxi')),
        );
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      seed: () =>
          BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
      act: (bloc) => bloc.add(
        CreateBudgetItem(
          tripId: 'trip-1',
          data: {'label': 'Taxi', 'amount': 30.0},
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BudgetLoaded;
        expect(state.items.length, 2);
        expect(state.summary.totalBudget, 1000);
      },
    );

    // ── UpdateBudgetItem ──────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'UpdateBudgetItem replaces item and refreshes summary',
      build: () {
        final updatedItem = makeBudgetItem(
          label: 'Updated Hotel',
          amount: 200.0,
        );
        when(
          () => mockBudgetRepo.updateBudgetItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(updatedItem));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary(totalSpent: 200)));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      seed: () =>
          BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
      act: (bloc) => bloc.add(
        UpdateBudgetItem(
          tripId: 'trip-1',
          itemId: 'budget-1',
          data: {'label': 'Updated Hotel', 'amount': 200.0},
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoaded>(), isA<BudgetLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BudgetLoaded;
        expect(state.items.length, 1);
        expect(state.items.first.label, 'Updated Hotel');
        expect(state.items.first.amount, 200.0);
        expect(state.summary.totalSpent, 200);
        verify(() => mockBudgetRepo.getBudgetSummary('trip-1')).called(1);
      },
    );

    // ── DeleteBudgetItem ────────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'DeleteBudgetItem removes item and refreshes summary',
      build: () {
        when(
          () => mockBudgetRepo.deleteBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockBudgetRepo.getBudgetSummary(any()),
        ).thenAnswer((_) async => Success(makeBudgetSummary(totalSpent: 120)));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      seed: () => BudgetLoaded(
        items: [
          makeBudgetItem(),
          makeBudgetItem(id: 'budget-2', label: 'Taxi'),
        ],
        summary: makeBudgetSummary(),
      ),
      act: (bloc) =>
          bloc.add(DeleteBudgetItem(tripId: 'trip-1', itemId: 'budget-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoaded>(), isA<BudgetLoaded>()],
      verify: (bloc) {
        final state = bloc.state as BudgetLoaded;
        expect(state.items.length, 1);
        expect(state.items.first.id, 'budget-2');
        expect(state.summary.totalSpent, 120);
        verify(() => mockBudgetRepo.getBudgetSummary('trip-1')).called(1);
        verifyNever(() => mockBudgetRepo.getBudgetItems(any()));
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'DeleteBudgetItem falls back to LoadBudget when state is not BudgetLoaded',
      build: () {
        when(
          () => mockBudgetRepo.deleteBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        stubLoadBudgetSuccess();
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteBudgetItem(tripId: 'trip-1', itemId: 'budget-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoading>(), isA<BudgetLoaded>()],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when DeleteBudgetItem fails',
      build: () {
        when(
          () => mockBudgetRepo.deleteBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteBudgetItem(tripId: 'trip-1', itemId: 'budget-1')),
      expect: () => [isA<BudgetError>()],
    );

    // ── EstimateBudget ────────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetEstimating, BudgetEstimated] when EstimateBudget succeeds from BudgetLoaded',
      build: () {
        when(
          () => mockBudgetRepo.estimateBudget(any()),
        ).thenAnswer((_) async => Success(makeBudgetEstimation()));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      seed: () =>
          BudgetLoaded(items: [makeBudgetItem()], summary: makeBudgetSummary()),
      act: (bloc) => bloc.add(EstimateBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetEstimating>(), isA<BudgetEstimated>()],
      verify: (bloc) {
        final state = bloc.state as BudgetEstimated;
        expect(state.items.length, 1);
        expect(state.summary.totalBudget, 1000);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetEstimating, BudgetEstimated] when EstimateBudget succeeds from initial state',
      build: () {
        when(
          () => mockBudgetRepo.estimateBudget(any()),
        ).thenAnswer((_) async => Success(makeBudgetEstimation()));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(EstimateBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetEstimating>(), isA<BudgetEstimated>()],
      verify: (bloc) {
        final state = bloc.state as BudgetEstimated;
        expect(state.items.isEmpty, true);
        expect(state.summary.totalBudget, 0);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetEstimating, BudgetQuotaExceeded] when EstimateBudget fails with QuotaExceededError',
      build: () {
        when(
          () => mockBudgetRepo.estimateBudget(any()),
        ).thenAnswer((_) async => const Failure(QuotaExceededError('quota')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(EstimateBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetEstimating>(), isA<BudgetQuotaExceeded>()],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetEstimating, BudgetError] when EstimateBudget fails with generic error',
      build: () {
        when(
          () => mockBudgetRepo.estimateBudget(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(EstimateBudget(tripId: 'trip-1')),
      expect: () => [isA<BudgetEstimating>(), isA<BudgetError>()],
    );

    // ── AcceptBudgetEstimate ──────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when AcceptBudgetEstimate succeeds and triggers LoadBudget',
      build: () {
        when(
          () => mockBudgetRepo.acceptBudgetEstimate(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        stubLoadBudgetSuccess();
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) =>
          bloc.add(AcceptBudgetEstimate(tripId: 'trip-1', budgetTotal: 1500.0)),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoading>(), isA<BudgetLoaded>()],
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetError] when AcceptBudgetEstimate fails',
      build: () {
        when(
          () => mockBudgetRepo.acceptBudgetEstimate(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) =>
          bloc.add(AcceptBudgetEstimate(tripId: 'trip-1', budgetTotal: 1500.0)),
      expect: () => [isA<BudgetError>()],
    );

    // ── CreateBudgetItem failure ──────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetError] when CreateBudgetItem API fails',
      build: () {
        when(
          () => mockBudgetRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Failure(NetworkError('err')));
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(
        CreateBudgetItem(
          tripId: 'trip-1',
          data: {'label': 'Taxi', 'amount': 30.0},
        ),
      ),
      expect: () => [isA<BudgetError>()],
    );

    // ── UpdateBudgetItem fallback ─────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'UpdateBudgetItem falls back to LoadBudget when state is not BudgetLoaded',
      build: () {
        when(
          () => mockBudgetRepo.updateBudgetItem(any(), any(), any()),
        ).thenAnswer((_) async => Success(makeBudgetItem(label: 'Updated')));
        stubLoadBudgetSuccess();
        return BudgetBloc(budgetRepository: mockBudgetRepo);
      },
      act: (bloc) => bloc.add(
        UpdateBudgetItem(
          tripId: 'trip-1',
          itemId: 'budget-1',
          data: {'label': 'Updated'},
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [isA<BudgetLoading>(), isA<BudgetLoaded>()],
    );
  });
}
