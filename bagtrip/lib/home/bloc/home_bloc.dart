import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _tripRepository;
  final AuthRepository _authRepository;

  HomeBloc({TripRepository? tripRepository, AuthRepository? authRepository})
    : _tripRepository = tripRepository ?? getIt<TripRepository>(),
      _authRepository = authRepository ?? getIt<AuthRepository>(),
      super(HomeInitial()) {
    on<LoadHome>(_onLoadHome);
  }

  Future<void> _onLoadHome(LoadHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    // Fetch user
    User? user;
    final userResult = await _authRepository.getCurrentUser();
    if (isClosed) return;
    user = userResult.dataOrNull;

    // Count total trips across all statuses
    int totalTrips = 0;
    for (final status in ['ongoing', 'planned', 'completed']) {
      final result = await _tripRepository.getTripsPaginated(
        status: status,
        limit: 1,
      );
      if (isClosed) return;
      if (result case Success(:final data)) {
        totalTrips += data.total;
      }
    }

    // Find next trip
    Trip? nextTrip;
    int? daysUntil;

    for (final status in ['ongoing', 'planned']) {
      final result = await _tripRepository.getTripsPaginated(
        status: status,
        limit: 1,
      );
      if (isClosed) return;
      if (result case Success(:final data)) {
        final trips = data.items;
        if (trips.isNotEmpty) {
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

    emit(
      HomeLoaded(
        user: user,
        nextTrip: nextTrip,
        daysUntilNextTrip: daysUntil,
        totalTrips: totalTrips,
      ),
    );
  }
}
