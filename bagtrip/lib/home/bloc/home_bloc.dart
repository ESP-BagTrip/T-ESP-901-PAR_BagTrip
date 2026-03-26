import 'dart:async';
import 'dart:developer' as dev;

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/home/helpers/trip_end_detector.dart';
import 'package:bagtrip/home/helpers/trip_mode_detector.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/repositories/weather_repository.dart';
import 'package:bagtrip/service/trip_notification_scheduler.dart';
import 'package:bloc/bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final TripRepository _tripRepository;
  final AuthRepository _authRepository;
  final ActivityRepository _activityRepository;
  final ConnectivityService _connectivityService;
  final WeatherRepository _weatherRepository;
  final TripNotificationScheduler _scheduler;
  final PostTripDismissalStorage _dismissalStorage;

  HomeBloc({
    TripRepository? tripRepository,
    AuthRepository? authRepository,
    ActivityRepository? activityRepository,
    ConnectivityService? connectivityService,
    WeatherRepository? weatherRepository,
    TripNotificationScheduler? scheduler,
    PostTripDismissalStorage? dismissalStorage,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _authRepository = authRepository ?? getIt<AuthRepository>(),
       _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
       _connectivityService =
           connectivityService ?? getIt<ConnectivityService>(),
       _weatherRepository = weatherRepository ?? getIt<WeatherRepository>(),
       _scheduler = scheduler ?? getIt<TripNotificationScheduler>(),
       _dismissalStorage =
           dismissalStorage ?? getIt<PostTripDismissalStorage>(),
       super(HomeInitial()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
    on<ConfirmTripCompletion>(_onConfirmTripCompletion);
    on<DismissTripCompletion>(_onDismissTripCompletion);
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

    // ── Auto-detect planned → ongoing ──
    final detectionResult = await detectAndTransitionTrips(
      plannedTrips: plannedTrips,
      tripRepository: _tripRepository,
      isOnline: _connectivityService.isOnline,
    );
    if (isClosed) return;

    final mutableOngoing = [...ongoingTrips];
    final mutablePlanned = [...plannedTrips];

    for (final trip in [
      ...detectionResult.transitionedTrips,
      ...detectionResult.failedTrips,
    ]) {
      mutablePlanned.removeWhere((t) => t.id == trip.id);
      if (!mutableOngoing.any((t) => t.id == trip.id)) {
        mutableOngoing.add(trip.copyWith(status: TripStatus.ongoing));
      }
    }

    // Schedule notifications for newly transitioned trips (fire-and-forget)
    for (final trip in detectionResult.transitionedTrips) {
      unawaited(
        _scheduler
            .scheduleOngoingNotifications(
              trip.copyWith(status: TripStatus.ongoing),
            )
            .catchError((e) => dev.log('Scheduler error: $e')),
      );
    }

    // ── Auto-detect ongoing → completed (endDate < today) ──
    final endResult = await detectEndedTrips(
      ongoingTrips: mutableOngoing,
      dismissalStorage: _dismissalStorage,
    );
    if (isClosed) return;

    Trip? pendingCompletionTrip;
    if (endResult.endedTrips.isNotEmpty) {
      pendingCompletionTrip = endResult.endedTrips.first;
    }

    // ── Decision tree ──────────────────────────────────────────────
    if (totalTrips == 0 && mutableOngoing.isEmpty) {
      emit(HomeNewUser(user: user));
      return;
    }

    if (mutableOngoing.isNotEmpty) {
      final activeTrip = _pickEarliestTrip(mutableOngoing);

      // Fetch today's activities + weather in parallel
      final contextualResults = await Future.wait([
        _activityRepository.getActivities(activeTrip.id),
        _weatherRepository.getWeather(activeTrip.id),
      ]);
      if (isClosed) return;

      final activitiesResult = contextualResults[0] as Result<List<Activity>>;
      final weatherResult = contextualResults[1] as Result<WeatherSummary>;

      List<Activity> todayActivities = [];
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

      String? weatherSummary;
      if (weatherResult is Success<WeatherSummary>) {
        final w = weatherResult.data;
        weatherSummary = '${w.avgTempC.round()}°C · ${w.description}';
      }

      // Schedule ongoing trip notifications (idempotent, fire-and-forget)
      unawaited(
        _scheduler
            .scheduleOngoingNotifications(activeTrip)
            .catchError((e) => dev.log('Scheduler error: $e')),
      );

      emit(
        HomeActiveTrip(
          user: user,
          activeTrip: activeTrip,
          todayActivities: todayActivities,
          weatherSummary: weatherSummary,
          allActivities: activitiesResult is Success<List<Activity>>
              ? activitiesResult.data
              : [],
          pendingCompletionTrip: pendingCompletionTrip,
        ),
      );
      return;
    }

    // Trip manager: has trips but none ongoing
    // Schedule packing reminders for planned trips (fire-and-forget)
    for (final trip in mutablePlanned) {
      unawaited(
        _scheduler
            .schedulePackingReminder(trip)
            .catchError((e) => dev.log('Scheduler error: $e')),
      );
    }

    final nextTrip = mutablePlanned.isNotEmpty
        ? _pickEarliestTrip(mutablePlanned)
        : null;

    emit(
      HomeTripManager(
        user: user,
        nextTrip: nextTrip,
        nextTripCompletion: tripCompletion(nextTrip),
        upcomingTrips: mutablePlanned,
        completedTrips: completedTrips,
      ),
    );
  }

  Future<void> _onConfirmTripCompletion(
    ConfirmTripCompletion event,
    Emitter<HomeState> emit,
  ) async {
    await _tripRepository.updateTripStatus(event.tripId, 'completed');
    // Find the trip to cancel notifications
    if (state is HomeActiveTrip) {
      final trip = (state as HomeActiveTrip).pendingCompletionTrip;
      if (trip != null) {
        unawaited(
          _scheduler
              .cancelTripNotifications(trip)
              .catchError((e) => dev.log('Cancel notif error: $e')),
        );
      }
    }
    await _dismissalStorage.clearDismissal(event.tripId);
    // Emit intermediate state with completedTripId for navigation
    if (state is HomeActiveTrip) {
      final s = state as HomeActiveTrip;
      emit(
        HomeActiveTrip(
          user: s.user,
          activeTrip: s.activeTrip,
          todayActivities: s.todayActivities,
          weatherSummary: s.weatherSummary,
          allActivities: s.allActivities,
          completedTripId: event.tripId,
        ),
      );
    }
    add(RefreshHome());
  }

  Future<void> _onDismissTripCompletion(
    DismissTripCompletion event,
    Emitter<HomeState> emit,
  ) async {
    await _dismissalStorage.recordDismissal(event.tripId);
    // Schedule a 24h reminder notification
    if (state is HomeActiveTrip) {
      final trip = (state as HomeActiveTrip).pendingCompletionTrip;
      if (trip != null) {
        unawaited(
          _scheduler
              .scheduleCompletionReminder(trip)
              .catchError((e) => dev.log('Scheduler error: $e')),
        );
      }
    }
    add(RefreshHome());
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
}
