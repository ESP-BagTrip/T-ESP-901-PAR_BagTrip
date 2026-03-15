part of 'budget_bloc.dart';

sealed class BudgetState {}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<BudgetItem> items;
  final BudgetSummary summary;

  BudgetLoaded({required this.items, required this.summary});
}

class BudgetEstimating extends BudgetState {}

class BudgetEstimated extends BudgetState {
  final BudgetEstimation estimation;
  final List<BudgetItem> items;
  final BudgetSummary summary;

  BudgetEstimated({
    required this.estimation,
    required this.items,
    required this.summary,
  });
}

class BudgetQuotaExceeded extends BudgetState {}

class BudgetError extends BudgetState {
  final AppError error;

  BudgetError({required this.error});
}
