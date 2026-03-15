import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bloc/bloc.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetRepository _budgetRepository;

  BudgetBloc({BudgetRepository? budgetRepository})
    : _budgetRepository = budgetRepository ?? getIt<BudgetRepository>(),
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
    final results = await Future.wait([
      _budgetRepository.getBudgetItems(event.tripId),
      _budgetRepository.getBudgetSummary(event.tripId),
    ]);
    if (isClosed) return;
    final itemsResult = results[0] as Result<List<BudgetItem>>;
    final summaryResult = results[1] as Result<BudgetSummary>;
    if (itemsResult is Success<List<BudgetItem>> &&
        summaryResult is Success<BudgetSummary>) {
      emit(BudgetLoaded(items: itemsResult.data, summary: summaryResult.data));
    } else {
      final error = itemsResult is Failure<List<BudgetItem>>
          ? itemsResult.error
          : (summaryResult as Failure<BudgetSummary>).error;
      emit(BudgetError(error: error));
    }
  }

  Future<void> _onCreateBudgetItem(
    CreateBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    final result = await _budgetRepository.createBudgetItem(
      event.tripId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadBudget(tripId: event.tripId));
      case Failure(:final error):
        emit(BudgetError(error: error));
    }
  }

  Future<void> _onUpdateBudgetItem(
    UpdateBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    final result = await _budgetRepository.updateBudgetItem(
      event.tripId,
      event.itemId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadBudget(tripId: event.tripId));
      case Failure(:final error):
        emit(BudgetError(error: error));
    }
  }

  Future<void> _onDeleteBudgetItem(
    DeleteBudgetItem event,
    Emitter<BudgetState> emit,
  ) async {
    final result = await _budgetRepository.deleteBudgetItem(
      event.tripId,
      event.itemId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadBudget(tripId: event.tripId));
      case Failure(:final error):
        emit(BudgetError(error: error));
    }
  }
}
