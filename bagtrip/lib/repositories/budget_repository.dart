import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/budget_item.dart';

abstract class BudgetRepository {
  Future<Result<List<BudgetItem>>> getBudgetItems(String tripId);
  Future<Result<BudgetSummary>> getBudgetSummary(String tripId);
  Future<Result<BudgetItem>> createBudgetItem(
    String tripId,
    Map<String, dynamic> data,
  );
  Future<Result<BudgetItem>> updateBudgetItem(
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  );
  Future<Result<void>> deleteBudgetItem(String tripId, String itemId);
}
