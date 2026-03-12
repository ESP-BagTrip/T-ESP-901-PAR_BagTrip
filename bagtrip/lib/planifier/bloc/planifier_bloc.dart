import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'planifier_event.dart';
part 'planifier_state.dart';

class PlanifierBloc extends Bloc<PlanifierEvent, PlanifierState> {
  PlanifierBloc() : super(PlanifierInitial()) {
    on<LoadPlanifier>(_onLoadPlanifier);
  }

  Future<void> _onLoadPlanifier(
    LoadPlanifier event,
    Emitter<PlanifierState> emit,
  ) async {
    emit(PlanifierLoaded());
  }
}
