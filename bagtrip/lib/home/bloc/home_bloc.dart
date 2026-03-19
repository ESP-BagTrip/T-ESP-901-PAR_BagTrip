import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
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

    final results = await Future.wait([
      _authRepository.getCurrentUser(),
      _tripRepository.getTripsPaginated(status: 'ongoing', limit: 1),
      _tripRepository.getTripsPaginated(status: 'planned', limit: 1),
      _tripRepository.getTripsPaginated(status: 'completed', limit: 1),
    ]);

    if (isClosed) return;

    final userResult = results[0] as Result<User?>;
    final ongoingResult = results[1] as Result<PaginatedResponse<Trip>>;
    final plannedResult = results[2] as Result<PaginatedResponse<Trip>>;
    final completedResult = results[3] as Result<PaginatedResponse<Trip>>;

    // Auth failure → HomeError
    if (userResult is Failure<User?>) {
      final error = userResult.error;
      if (error is AuthenticationError) {
        emit(HomeError(error: error));
        return;
      }
    }

    // All trip calls failed → HomeError
    if (ongoingResult is Failure &&
        plannedResult is Failure &&
        completedResult is Failure) {
      emit(HomeError(error: (ongoingResult as Failure).error));
      return;
    }

    final user = userResult.dataOrNull;

    // Count totals from same responses (no extra API calls)
    int totalTrips = 0;
    if (ongoingResult case Success(:final data)) totalTrips += data.total;
    if (plannedResult case Success(:final data)) totalTrips += data.total;
    if (completedResult case Success(:final data)) totalTrips += data.total;

    // Extract next trip from ongoing then planned (reuse same data)
    Trip? nextTrip;
    int? daysUntil;
    for (final result in [ongoingResult, plannedResult]) {
      if (result case Success(:final data)) {
        if (data.items.isNotEmpty) {
          final sorted = [...data.items]
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

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
