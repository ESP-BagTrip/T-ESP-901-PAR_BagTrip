import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _tripRepository;
  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;

  HomeBloc({
    TripRepository? tripRepository,
    AuthRepository? authRepository,
    ActivityRepository? activityRepository,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
       super(HomeInitial()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
  }

  Future<void> _onLoadHome(LoadHome event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _fetchAndEmitContextualState(emit);
  }

  Future<void> _onRefreshHome(
    RefreshHome event,
    Emitter<HomeState> emit,
  ) async {
    await _fetchAndEmitContextualState(emit);
  }

  Future<void> _fetchAndEmitContextualState(Emitter<HomeState> emit) async {
    final results = await Future.wait([
      _authRepository.getCurrentUser(),
      _tripRepository.getTripsPaginated(status: 'ongoing', limit: 5),
      _tripRepository.getTripsPaginated(status: 'planned', limit: 5),
      _tripRepository.getTripsPaginated(status: 'completed', limit: 5),
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

    // User with fallback
    final user = userResult.dataOrNull ?? const User(id: '', email: '');

    // Count totals
    int totalTrips = 0;
    if (ongoingResult case Success(:final data)) totalTrips += data.total;
    if (plannedResult case Success(:final data)) totalTrips += data.total;
    if (completedResult case Success(:final data)) totalTrips += data.total;

    // Extract trip lists
    final ongoingTrips = ongoingResult is Success<PaginatedResponse<Trip>>
        ? ongoingResult.data.items
        : <Trip>[];
    final plannedTrips = plannedResult is Success<PaginatedResponse<Trip>>
        ? plannedResult.data.items
        : <Trip>[];
    final completedTrips = completedResult is Success<PaginatedResponse<Trip>>
        ? completedResult.data.items
        : <Trip>[];

    // ── Decision tree ──────────────────────────────────────────────
    if (totalTrips == 0) {
      emit(HomeNewUser(user: user));
      return;
    }

    if (ongoingTrips.isNotEmpty) {
      final activeTrip = _pickEarliestTrip(ongoingTrips);

      // Fetch today's activities
      List<Activity> todayActivities = [];
      final activitiesResult = await _activityRepository.getActivities(
        activeTrip.id,
      );
      if (isClosed) return;

      if (activitiesResult is Success<List<Activity>>) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        todayActivities =
            activitiesResult.data.where((a) {
              final actDate = DateTime(a.date.year, a.date.month, a.date.day);
              return actDate == today;
            }).toList()..sort((a, b) {
              final aTime = a.startTime ?? '';
              final bTime = b.startTime ?? '';
              return aTime.compareTo(bTime);
            });
      }

      emit(
        HomeActiveTrip(
          user: user,
          activeTrip: activeTrip,
          todayActivities: todayActivities,
          allActivities: activitiesResult is Success<List<Activity>>
              ? activitiesResult.data
              : [],
        ),
      );
      return;
    }

    // Trip manager: has trips but none ongoing
    final nextTrip = plannedTrips.isNotEmpty
        ? _pickEarliestTrip(plannedTrips)
        : null;

    emit(
      HomeTripManager(
        user: user,
        nextTrip: nextTrip,
        nextTripCompletion: tripCompletion(nextTrip),
        upcomingTrips: plannedTrips,
        completedTrips: completedTrips,
      ),
    );
  }

  Trip _pickEarliestTrip(List<Trip> trips) {
    final sorted = [...trips]
      ..sort((a, b) {
        final aDate = a.startDate;
        final bDate = b.startDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
    return sorted.first;
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
