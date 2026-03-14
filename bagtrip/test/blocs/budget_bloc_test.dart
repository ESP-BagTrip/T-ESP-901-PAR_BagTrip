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
      'triggers LoadBudget internally after CreateBudgetItem succeeds',
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
      expect: () => [
        // CreateBudgetItem success triggers add(LoadBudget)
        isA<BudgetLoading>(),
        isA<BudgetLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockBudgetRepo.createBudgetItem('trip-1', any()),
        ).called(1);
      },
    );

    // ── DeleteBudgetItem ────────────────────────────────────────────────

    blocTest<BudgetBloc, BudgetState>(
      'triggers LoadBudget internally after DeleteBudgetItem succeeds',
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
      verify: (_) {
        verify(
          () => mockBudgetRepo.deleteBudgetItem('trip-1', 'budget-1'),
        ).called(1);
      },
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
  });
}
