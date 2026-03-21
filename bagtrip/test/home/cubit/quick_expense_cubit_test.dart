import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/cubit/quick_expense_cubit.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  late MockBudgetRepository mockRepo;

  setUp(() {
    mockRepo = MockBudgetRepository();
  });

  group('QuickExpenseCubit', () {
    test('initial state is QuickExpenseInitial', () {
      final cubit = QuickExpenseCubit(repo: mockRepo);
      expect(cubit.state, isA<QuickExpenseInitial>());
      cubit.close();
    });

    blocTest<QuickExpenseCubit, QuickExpenseState>(
      'emits [Saving, Saved] on success',
      setUp: () {
        when(() => mockRepo.createBudgetItem(any(), any())).thenAnswer(
          (_) async => Success(
            BudgetItem(
              id: '1',
              tripId: 'trip1',
              label: 'FOOD',
              amount: 12.5,
              category: BudgetCategory.food,
              date: DateTime.now(),
              isPlanned: false,
            ),
          ),
        );
      },
      build: () => QuickExpenseCubit(repo: mockRepo),
      act: (cubit) => cubit.saveExpense(
        tripId: 'trip1',
        amount: 12.5,
        category: BudgetCategory.food,
      ),
      expect: () => [isA<QuickExpenseSaving>(), isA<QuickExpenseSaved>()],
    );

    blocTest<QuickExpenseCubit, QuickExpenseState>(
      'emits [Saving, Error] on failure',
      setUp: () {
        when(
          () => mockRepo.createBudgetItem(any(), any()),
        ).thenAnswer((_) async => const Failure(UnknownError('fail')));
      },
      build: () => QuickExpenseCubit(repo: mockRepo),
      act: (cubit) => cubit.saveExpense(
        tripId: 'trip1',
        amount: 10,
        category: BudgetCategory.transport,
      ),
      expect: () => [isA<QuickExpenseSaving>(), isA<QuickExpenseError>()],
    );
  });
}
