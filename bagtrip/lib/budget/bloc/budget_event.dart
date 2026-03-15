part of 'budget_bloc.dart';

sealed class BudgetEvent {}

class LoadBudget extends BudgetEvent {
  final String tripId;

  LoadBudget({required this.tripId});
}

class CreateBudgetItem extends BudgetEvent {
  final String tripId;
  final Map<String, dynamic> data;

  CreateBudgetItem({required this.tripId, required this.data});
}

class UpdateBudgetItem extends BudgetEvent {
  final String tripId;
  final String itemId;
  final Map<String, dynamic> data;

  UpdateBudgetItem({
    required this.tripId,
    required this.itemId,
    required this.data,
  });
}

class DeleteBudgetItem extends BudgetEvent {
  final String tripId;
  final String itemId;

  DeleteBudgetItem({required this.tripId, required this.itemId});
}

class EstimateBudget extends BudgetEvent {
  final String tripId;

  EstimateBudget({required this.tripId});
}

class AcceptBudgetEstimate extends BudgetEvent {
  final String tripId;
  final double budgetTotal;

  AcceptBudgetEstimate({required this.tripId, required this.budgetTotal});
}
