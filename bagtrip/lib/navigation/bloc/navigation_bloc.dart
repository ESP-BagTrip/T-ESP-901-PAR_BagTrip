import 'package:bloc/bloc.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabChanged>(_onTabChanged);
  }

  Future<void> _onTabChanged(
    NavigationTabChanged event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(activeTab: event.tab));
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
