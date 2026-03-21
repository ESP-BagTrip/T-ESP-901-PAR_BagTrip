import 'dart:async';

import 'package:bloc/bloc.dart';

class TodayTickCubit extends Cubit<DateTime> {
  Timer? _timer;

  TodayTickCubit({DateTime? initialNow}) : super(initialNow ?? DateTime.now()) {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!isClosed) emit(DateTime.now());
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
