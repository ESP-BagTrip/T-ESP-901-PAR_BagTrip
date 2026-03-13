part of 'budget_bloc.dart';

sealed class BudgetState {}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetLoaded extends BudgetState {
  final List<BudgetItem> items;
  final BudgetSummary summary;

  BudgetLoaded({required this.items, required this.summary});
}

class BudgetError extends BudgetState {
  final String message;

  BudgetError({required this.message});
}
