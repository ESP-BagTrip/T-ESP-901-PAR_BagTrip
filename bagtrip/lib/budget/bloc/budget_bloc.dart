import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/service/budget_service.dart';
import 'package:bloc/bloc.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetService _budgetService;

  BudgetBloc({BudgetService? budgetService})
    : _budgetService = budgetService ?? getIt<BudgetService>(),
      super(BudgetInitial()) {
    on<LoadBudget>(_onLoadBudget);
    on<CreateBudgetItem>(_onCreateBudgetItem);
    on<UpdateBudgetItem>(_onUpdateBudgetItem);
    on<DeleteBudgetItem>(_onDeleteBudgetItem);
  }

  Future<void> _onLoadBudget(
    LoadBudget event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final results = await Future.wait([
        _budgetService.getBudgetItems(event.tripId),
        _budgetService.getBudgetSummary(event.tripId),
      ]);
      emit(
        BudgetLoaded(
          items: results[0] as List<BudgetItem>,
          summary: results[1] as BudgetSummary,
        ),
      );
    } catch (e) {
      emit(BudgetError(message: e.toString()));
    }
  }

  Future<void> _onCreateBudgetItem(
    CreateBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _budgetService.createBudgetItem(event.tripId, event.data);
      add(LoadBudget(tripId: event.tripId));
    } catch (e) {
      emit(BudgetError(message: e.toString()));
    }
  }

  Future<void> _onUpdateBudgetItem(
    UpdateBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _budgetService.updateBudgetItem(
        event.tripId,
        event.itemId,
        event.data,
      );
      add(LoadBudget(tripId: event.tripId));
    } catch (e) {
      emit(BudgetError(message: e.toString()));
    }
  }

  Future<void> _onDeleteBudgetItem(
    DeleteBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      await _budgetService.deleteBudgetItem(event.tripId, event.itemId);
      add(LoadBudget(tripId: event.tripId));
    } catch (e) {
      emit(BudgetError(message: e.toString()));
    }
  }
}
