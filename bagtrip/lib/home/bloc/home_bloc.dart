import 'dart:developer' as dev;

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/home/helpers/trip_completion.dart';
import 'package:bagtrip/home/helpers/trip_end_detector.dart';
import 'package:bagtrip/home/helpers/trip_mode_detector.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/home_summary.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/home_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/utils/destination_time.dart';
import 'package:bloc/bloc.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Handler key under which the PLANNED→ONGOING offline transition is replayed
/// by the central [OfflineWriteQueue]. Format is `<repository>:<method>`,
/// matching how [OfflineWriteQueue.replay] looks up handlers.
const String kHomeTripStatusReplayKey = 'trip:updateTripStatus';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final TripRepository _tripRepository;
  final ConnectivityService _connectivityService;
  final PostTripDismissalStorage _dismissalStorage;
  final OfflineWriteQueue _offlineWriteQueue;

  bool _preferIdleDespiteOngoing = false;

  HomeBloc({
    HomeRepository? homeRepository,
    TripRepository? tripRepository,
    ConnectivityService? connectivityService,
    PostTripDismissalStorage? dismissalStorage,
    OfflineWriteQueue? offlineWriteQueue,
  }) : _homeRepository = homeRepository ?? getIt<HomeRepository>(),
       _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _connectivityService =
           connectivityService ?? getIt<ConnectivityService>(),
       _dismissalStorage =
           dismissalStorage ?? getIt<PostTripDismissalStorage>(),
       _offlineWriteQueue = offlineWriteQueue ?? getIt<OfflineWriteQueue>(),
       super(HomeInitial()) {
    on<LoadHome>(_onLoadHome);
    on<RefreshHome>(_onRefreshHome);
    on<ResetHome>(_onResetHome);
    on<ConfirmTripCompletion>(_onConfirmTripCompletion);
    on<DismissTripCompletion>(_onDismissTripCompletion);
    on<PreferIdleHomeOverview>(_onPreferIdleHomeOverview);
    on<ResumeActiveTripHome>(_onResumeActiveTripHome);
    on<CompleteActiveTrip>(_onCompleteActiveTrip);

    // Persist the PLANNED→ONGOING offline transition in the central
    // OfflineWriteQueue (Hive-backed) so it survives an app kill and is
    // replayed by the queue's own connectivity listener (wired in main.dart
    // via startListening()). The handler is registered exactly once here.
    //
    // We deliberately DROP the previous in-memory `_pendingOfflineTransitions`
    // list + `_ConnectivityRestored` replay path: the queue is now the single
    // source of truth for replaying the status update, which avoids the trip
    // being PATCHed twice on reconnect. The UI still flips to ongoing
    // optimistically inside `_fetchAndEmitContextualState` (no persisted state
    // needed for that — it is derived from the trip dates each load).
    _offlineWriteQueue.registerHandler(kHomeTripStatusReplayKey, (
      arguments,
    ) async {
      final tripId = arguments['tripId'] as String?;
      final status = arguments['status'] as String?;
      if (tripId == null || status == null) {
        // Malformed payload — drop it (return true) so it never blocks the
        // queue. This should not happen given how we enqueue below.
        dev.log('HomeBloc replay: malformed trip:updateTripStatus payload');
        return true;
      }
      final result = await _tripRepository.updateTripStatus(tripId, status);
      return result is Success;
    });
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

  void _onResetHome(ResetHome event, Emitter<HomeState> emit) {
    _preferIdleDespiteOngoing = false;
    emit(HomeInitial());
  }

  Future<void> _onPreferIdleHomeOverview(
    PreferIdleHomeOverview event,
    Emitter<HomeState> emit,
  ) async {
    _preferIdleDespiteOngoing = true;
    await _fetchAndEmitContextualState(emit);
  }

  Future<void> _onResumeActiveTripHome(
    ResumeActiveTripHome event,
    Emitter<HomeState> emit,
  ) async {
    _preferIdleDespiteOngoing = false;
    await _fetchAndEmitContextualState(emit);
  }

  Future<void> _onCompleteActiveTrip(
    CompleteActiveTrip event,
    Emitter<HomeState> emit,
  ) async {
    if (state is! HomeActiveTrip) return;
    final trip = (state as HomeActiveTrip).activeTrip;
    final result = await _tripRepository.updateTripStatus(trip.id, 'completed');
    if (isClosed) return;
    if (result is Failure) {
      dev.log('CompleteActiveTrip: updateTripStatus failed');
      return;
    }
    _preferIdleDespiteOngoing = false;
    await _fetchAndEmitContextualState(emit);
  }

  Future<void> _fetchAndEmitContextualState(Emitter<HomeState> emit) async {
    // SMP327-021: single aggregated read replacing the previous home fan-out
    // (3 paginated trip reads + /auth/me + active-trip activities + weather).
    final homeResult = await _homeRepository.getHome();

    if (isClosed) return;

    // Aggregated read failed → HomeError. AuthenticationError (expired session)
    // is surfaced like before so the auth redirect path can kick in.
    if (homeResult case Failure(:final error)) {
      emit(HomeError(error: error));
      return;
    }

    final summary = (homeResult as Success<HomeSummary>).data;

    final user = summary.user;

    // The server returns each list pre-capped (max 5) and pre-sorted; we keep
    // them as the source of truth for the contextual decision tree below.
    final ongoingTrips = summary.ongoingTrips;
    final plannedTrips = summary.plannedTrips;
    final completedTrips = summary.completedTrips;

    // `/home` no longer returns total counts (it caps each list at 5). The
    // decision tree only needs to know whether the user has *any* trip, which
    // we derive from the (capped) list contents.
    final hasAnyTrips =
        ongoingTrips.isNotEmpty ||
        plannedTrips.isNotEmpty ||
        completedTrips.isNotEmpty;

    // Activities + weather for the first ongoing trip are already part of the
    // aggregated payload — no separate calls.
    final activeTripActivities = summary.activeTripActivities;
    final activeTripWeather = summary.activeTripWeather;

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

    // Persist offline transitions in the central OfflineWriteQueue so they
    // survive an app kill and are replayed by the queue on reconnect. The UI
    // already shows these trips as ongoing (optimistic, via mutableOngoing
    // above) — enqueueing only handles the deferred server-side PATCH.
    if (!_connectivityService.isOnline &&
        detectionResult.transitionedTrips.isNotEmpty) {
      for (final trip in detectionResult.transitionedTrips) {
        await _offlineWriteQueue.enqueue(
          PendingWriteOperation(
            id: 'trip-status-${trip.id}',
            repository: 'trip',
            method: 'updateTripStatus',
            arguments: {'tripId': trip.id, 'status': 'ongoing'},
            createdAt: DateTime.now(),
          ),
        );
      }
      if (isClosed) return;
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
    if (!hasAnyTrips && mutableOngoing.isEmpty) {
      emit(HomeIdle(user: user));
      return;
    }

    if (mutableOngoing.isNotEmpty) {
      final activeTrip = _pickEarliestTrip(mutableOngoing);

      if (_preferIdleDespiteOngoing) {
        _emitTripManagerIdle(
          emit,
          user: user,
          mutablePlanned: mutablePlanned,
          completedTrips: completedTrips,
          backgroundOngoingTrip: activeTrip,
        );
        return;
      }

      // Activities + weather come from the aggregated `/home` payload (server
      // computes them for the first ongoing trip). We still derive *today*'s
      // slice client-side using the destination timezone, matching the prior
      // behaviour.
      final allActivities = activeTripActivities;
      final now = nowInDestination(activeTrip.destinationTimezone);
      final today = DateTime(now.year, now.month, now.day);
      final todayActivities =
          allActivities.where((a) {
            final ad = a.date;
            if (ad == null) return false;
            final actDate = DateTime(ad.year, ad.month, ad.day);
            return actDate == today;
          }).toList()..sort((a, b) {
            final aTime = a.startTime ?? '';
            final bTime = b.startTime ?? '';
            return aTime.compareTo(bTime);
          });

      String? weatherSummary;
      WeatherSummary? weatherData;
      if (activeTripWeather != null) {
        final w = activeTripWeather;
        weatherSummary = '${w.avgTempC.round()}°C · ${w.description}';
        weatherData = w;
      }

      emit(
        HomeActiveTrip(
          user: user,
          activeTrip: activeTrip,
          upcomingTrips: mutablePlanned,
          todayActivities: todayActivities,
          weatherSummary: weatherSummary,
          weatherData: weatherData,
          allActivities: allActivities,
          pendingCompletionTrip: pendingCompletionTrip,
        ),
      );
      return;
    }

    // Trip manager: has trips but none ongoing
    _emitTripManagerIdle(
      emit,
      user: user,
      mutablePlanned: mutablePlanned,
      completedTrips: completedTrips,
    );
  }

  void _emitTripManagerIdle(
    Emitter<HomeState> emit, {
    required User user,
    required List<Trip> mutablePlanned,
    required List<Trip> completedTrips,
    Trip? backgroundOngoingTrip,
  }) {
    final nextTrip = mutablePlanned.isNotEmpty
        ? _pickEarliestTrip(mutablePlanned)
        : null;

    emit(
      HomeIdle(
        user: user,
        nextTrip: nextTrip,
        nextTripCompletion: tripCompletion(nextTrip),
        upcomingTrips: mutablePlanned,
        completedTrips: completedTrips,
        backgroundOngoingTrip: backgroundOngoingTrip,
      ),
    );
  }

  Future<void> _onConfirmTripCompletion(
    ConfirmTripCompletion event,
    Emitter<HomeState> emit,
  ) async {
    await _tripRepository.updateTripStatus(event.tripId, 'completed');
    await _dismissalStorage.clearDismissal(event.tripId);
    // Emit intermediate state with completedTripId for navigation
    if (state is HomeActiveTrip) {
      final s = state as HomeActiveTrip;
      emit(
        HomeActiveTrip(
          user: s.user,
          activeTrip: s.activeTrip,
          upcomingTrips: s.upcomingTrips,
          todayActivities: s.todayActivities,
          weatherSummary: s.weatherSummary,
          weatherData: s.weatherData,
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
