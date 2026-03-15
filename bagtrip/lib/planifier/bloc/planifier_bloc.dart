import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'planifier_event.dart';
part 'planifier_state.dart';

class PlanifierBloc extends Bloc<PlanifierEvent, PlanifierState> {
  final TripRepository _tripRepository;

  PlanifierBloc({TripRepository? tripRepository})
    : _tripRepository = tripRepository ?? getIt<TripRepository>(),
      super(PlanifierInitial()) {
    on<LoadPlanifier>(_onLoadPlanifier);
  }

  Future<void> _onLoadPlanifier(
    LoadPlanifier event,
    Emitter<PlanifierState> emit,
  ) async {
    Trip? nextTrip;
    int? daysUntil;

    // Try ongoing first, then planned
    for (final status in ['ongoing', 'planned']) {
      final result = await _tripRepository.getTripsPaginated(
        status: status,
        limit: 1,
      );
      if (result case Success(:final data)) {
        final trips = data.items;
        if (trips.isNotEmpty) {
          // Pick the one with the earliest startDate
          final sorted = [...trips]
            ..sort((a, b) {
              final aDate = a.startDate;
              final bDate = b.startDate;
              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return aDate.compareTo(bDate);
            });
          nextTrip = sorted.first;
          if (nextTrip.startDate != null) {
            daysUntil = nextTrip.startDate!.difference(DateTime.now()).inDays;
            if (daysUntil < 0) daysUntil = 0;
          }
          break;
        }
      }
    }

    emit(PlanifierLoaded(nextTrip: nextTrip, daysUntilNextTrip: daysUntil));
  }
}
