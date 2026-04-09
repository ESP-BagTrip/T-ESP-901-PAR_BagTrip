import 'dart:async';

import 'package:bagtrip/utils/destination_time.dart';
import 'package:bloc/bloc.dart';

class TodayTickCubit extends Cubit<DateTime> {
  Timer? _timer;
  final String? _destinationTimezone;

  TodayTickCubit({DateTime? initialNow, String? destinationTimezone})
    : _destinationTimezone = destinationTimezone,
      super(initialNow ?? nowInDestination(destinationTimezone)) {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!isClosed) emit(nowInDestination(_destinationTimezone));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
