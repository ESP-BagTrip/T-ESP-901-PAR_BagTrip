import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

sealed class QuickExpenseState {}

class QuickExpenseInitial extends QuickExpenseState {}

class QuickExpenseSaving extends QuickExpenseState {}

class QuickExpenseSaved extends QuickExpenseState {
  final BudgetItem item;
  QuickExpenseSaved({required this.item});
}

class QuickExpenseError extends QuickExpenseState {
  final AppError error;
  QuickExpenseError({required this.error});
}

class QuickExpenseCubit extends Cubit<QuickExpenseState> {
  final BudgetRepository _repo;

  QuickExpenseCubit({BudgetRepository? repo})
    : _repo = repo ?? getIt<BudgetRepository>(),
      super(QuickExpenseInitial());

  Future<void> saveExpense({
    required String tripId,
    required double amount,
    required BudgetCategory category,
    String? note,
  }) async {
    emit(QuickExpenseSaving());
    final data = {
      'label': note?.isNotEmpty == true ? note! : category.name.toUpperCase(),
      'amount': amount,
      'category': category.name.toUpperCase(),
      'isPlanned': false,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
    final result = await _repo.createBudgetItem(tripId, data);
    switch (result) {
      case Success(:final data):
        emit(QuickExpenseSaved(item: data));
      case Failure(:final error):
        emit(QuickExpenseError(error: error));
    }
  }
}
