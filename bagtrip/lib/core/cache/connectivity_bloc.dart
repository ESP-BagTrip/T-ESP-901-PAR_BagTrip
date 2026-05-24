import 'dart:async';

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  late final StreamSubscription<bool> _subscription;

  ConnectivityBloc({ConnectivityService? connectivityService})
    : super(ConnectivityOnline()) {
    final service = connectivityService ?? getIt<ConnectivityService>();

    on<ConnectivityChanged>((event, emit) {
      emit(event.isOnline ? ConnectivityOnline() : ConnectivityOffline());
    });

    // Emit initial state based on current connectivity
    if (!service.isOnline) {
      add(ConnectivityChanged(isOnline: false));
    }

    _subscription = service.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChanged(isOnline: isOnline));
    });
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
