import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/trip_detail/helpers/trip_detail_completion.dart';
import 'package:bagtrip/utils/destination_time.dart';
import 'package:bloc/bloc.dart';

part 'trip_detail_event.dart';
part 'trip_detail_state.dart';
part 'trip_detail_trip_handlers.dart';
part 'trip_detail_activity_handlers.dart';
part 'trip_detail_transport_handlers.dart';
part 'trip_detail_baggage_handlers.dart';
part 'trip_detail_budget_handlers.dart';
part 'trip_detail_misc_handlers.dart';

/// Central hub for a trip's detail screen.
///
/// Owns the shared [TripDetailLoaded] state (trip + activities + flights +
/// accommodations + baggage + budget summary + shares + completion) and wires
/// every mutation event to its domain-specific handler. Domain handlers live
/// in the sibling `trip_detail_*_handlers.dart` part files of this library
/// so each concern sits in its own ~100-200 line file, while the state itself
/// stays unified (every mutation needs to recompute `completionResult` against
/// the full snapshot).
class TripDetailBloc extends Bloc<TripDetailEvent, TripDetailState> {
  final TripRepository _tripRepository;
  final ActivityRepository _activityRepository;
  final AccommodationRepository _accommodationRepository;
  final BaggageRepository _baggageRepository;
  final BudgetRepository _budgetRepository;
  final TransportRepository _transportRepository;
  final TripShareRepository _tripShareRepository;

  String? _tripId;

  TripDetailBloc({
    TripRepository? tripRepository,
    ActivityRepository? activityRepository,
    AccommodationRepository? accommodationRepository,
    BaggageRepository? baggageRepository,
    BudgetRepository? budgetRepository,
    TransportRepository? transportRepository,
    TripShareRepository? tripShareRepository,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
       _accommodationRepository =
           accommodationRepository ?? getIt<AccommodationRepository>(),
       _baggageRepository = baggageRepository ?? getIt<BaggageRepository>(),
       _budgetRepository = budgetRepository ?? getIt<BudgetRepository>(),
       _transportRepository =
           transportRepository ?? getIt<TransportRepository>(),
       _tripShareRepository =
           tripShareRepository ?? getIt<TripShareRepository>(),
       super(TripDetailInitial()) {
    // Core lifecycle + shared state transitions.
    on<LoadTripDetail>(_onLoadTripDetail);
    on<RefreshTripDetail>(_onRefreshTripDetail);
    on<LoadDeferredSections>(_onLoadDeferredSections);
    on<RetryDeferredSection>(_onRetryDeferredSection);
    on<SelectDay>(_onSelectDay);
    on<ToggleSection>(_onToggleSection);

    // Trip metadata (see trip_detail_trip_handlers.dart).
    on<UpdateTripStatus>(_onUpdateTripStatus);
    on<UpdateTripTitle>(_onUpdateTripTitle);
    on<UpdateTripDates>(_onUpdateTripDates);
    on<UpdateTripTravelers>(_onUpdateTripTravelers);
    on<UpdateTripTrackingFromDetail>(_onUpdateTripTracking);
    on<DeleteTripDetail>(_onDeleteTrip);

    // Activities (see trip_detail_activity_handlers.dart).
    on<ValidateActivity>(_onValidateActivity);
    on<RejectActivity>(_onRejectActivity);
    on<BatchValidateActivitiesFromDetail>(_onBatchValidateActivities);
    on<UpdateActivityFromDetail>(_onUpdateActivityFromDetail);
    on<MoveActivityToDay>(_onMoveActivityToDay);
    on<SuggestActivitiesForDay>(_onSuggestActivitiesForDay);
    on<ClearDaySuggestions>(_onClearDaySuggestions);
    on<CreateActivityFromDetail>(_onCreateActivityFromDetail);

    // Transport: flights + accommodations
    // (see trip_detail_transport_handlers.dart).
    on<AddFlightToDetail>(_onAddFlightToDetail);
    on<CreateFlightFromDetail>(_onCreateFlightFromDetail);
    on<UpdateFlightFromDetail>(_onUpdateFlightFromDetail);
    on<DeleteFlightFromDetail>(_onDeleteFlight);
    on<CreateAccommodationFromDetail>(_onCreateAccommodationFromDetail);
    on<UpdateAccommodationFromDetail>(_onUpdateAccommodationFromDetail);
    on<DeleteAccommodationFromDetail>(_onDeleteAccommodation);

    // Baggage (see trip_detail_baggage_handlers.dart).
    on<ToggleBaggagePackedFromDetail>(_onToggleBaggagePacked);
    on<CreateBaggageItemFromDetail>(_onCreateBaggageItemFromDetail);
    on<UpdateBaggageItemFromDetail>(_onUpdateBaggageItemFromDetail);
    on<DeleteBaggageItemFromDetail>(_onDeleteBaggageItem);

    // Budget (see trip_detail_budget_handlers.dart).
    on<CreateBudgetItemFromDetail>(_onCreateBudgetItemFromDetail);
    on<UpdateBudgetItemFromDetail>(_onUpdateBudgetItemFromDetail);
    on<DeleteBudgetItemFromDetail>(_onDeleteBudgetItemFromDetail);
    on<RefreshBudgetSummaryFromDetail>(_onRefreshBudgetSummaryFromDetail);

    // Shares (see trip_detail_misc_handlers.dart).
    on<CreateShareFromDetail>(_onCreateShareFromDetail);
    on<DeleteShareFromDetail>(_onDeleteShare);
  }

  // ─── Core handlers ────────────────────────────────────────────────────

  Future<void> _onLoadTripDetail(
    LoadTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    _tripId = event.tripId;
    emit(TripDetailLoading());
    await _fetchCore(event.tripId, emit);
  }

  Future<void> _onRefreshTripDetail(
    RefreshTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;
    await _fetchAllForRefresh(_tripId!, emit);
  }

  Future<void> _onLoadDeferredSections(
    LoadDeferredSections event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;
    if (loaded.deferredLoaded) return;

    final results = await Future.wait([
      _transportRepository.getManualFlights(_tripId!),
      _accommodationRepository.getByTrip(_tripId!),
      _baggageRepository.getByTrip(_tripId!),
      _budgetRepository.getBudgetSummary(_tripId!),
      _budgetRepository.getBudgetItems(_tripId!),
      _tripShareRepository.getSharesByTrip(_tripId!),
    ]);

    if (isClosed) return;
    if (state is! TripDetailLoaded) return;
    final current = state as TripDetailLoaded;

    final sectionErrors = <String, AppError>{};

    final flightsResult = results[0] as Result<List<ManualFlight>>;
    final flights = switch (flightsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['flights'] = error;
        return <ManualFlight>[];
      }(),
    };

    final accommodationsResult = results[1] as Result<List<Accommodation>>;
    final accommodations = switch (accommodationsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['accommodations'] = error;
        return <Accommodation>[];
      }(),
    };

    final baggageResult = results[2] as Result<List<BaggageItem>>;
    final baggageItems = switch (baggageResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['baggage'] = error;
        return <BaggageItem>[];
      }(),
    };

    final budgetResult = results[3] as Result<BudgetSummary>;
    final BudgetSummary? budgetSummary = switch (budgetResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['budget'] = error;
        return null;
      }(),
    };

    final budgetItemsResult = results[4] as Result<List<BudgetItem>>;
    final budgetItems = switch (budgetItemsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['budget'] = error;
        return <BudgetItem>[];
      }(),
    };

    final sharesResult = results[5] as Result<List<TripShare>>;
    final shares = switch (sharesResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['shares'] = error;
        return <TripShare>[];
      }(),
    };

    final completion = tripDetailCompletion(
      trip: current.trip,
      flights: flights,
      accommodations: accommodations,
      activities: current.activities,
      baggageItems: baggageItems,
    );

    emit(
      current.copyWith(
        flights: flights,
        accommodations: accommodations,
        baggageItems: baggageItems,
        budgetSummary: budgetSummary,
        budgetItems: budgetItems,
        shares: shares,
        completionResult: completion,
        deferredLoaded: true,
        sectionErrors: sectionErrors,
      ),
    );
  }

  /// Tier 1 — Trip + Activities only. Schedules deferred load after emit.
  Future<void> _fetchCore(String tripId, Emitter<TripDetailState> emit) async {
    final results = await Future.wait([
      _tripRepository.getTripById(tripId),
      _activityRepository.getActivities(tripId),
    ]);

    if (isClosed) return;

    final tripResult = results[0] as Result<Trip>;
    final activitiesResult = results[1] as Result<List<Activity>>;

    final Trip trip;
    switch (tripResult) {
      case Success(:final data):
        trip = data;
      case Failure(:final error):
        emit(TripDetailError(error: error));
        return;
    }
    final activities = activitiesResult.dataOrNull ?? [];

    final completion = tripDetailCompletion(
      trip: trip,
      flights: const [],
      accommodations: const [],
      activities: activities,
      baggageItems: const [],
    );

    emit(
      TripDetailLoaded(
        trip: trip,
        activities: activities,
        flights: const [],
        accommodations: const [],
        baggageItems: const [],
        shares: const [],
        userRole: trip.role ?? 'OWNER',
        completionResult: completion,
      ),
    );

    // Schedule deferred sections load
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) add(LoadDeferredSections());
    });
  }

  /// Full fetch for refresh — all 7 calls in parallel, deferredLoaded = true.
  Future<void> _fetchAllForRefresh(
    String tripId,
    Emitter<TripDetailState> emit,
  ) async {
    final int prevSelectedDay;
    final Set<String> prevCollapsedSections;
    if (state is TripDetailLoaded) {
      final loaded = state as TripDetailLoaded;
      prevSelectedDay = loaded.selectedDayIndex;
      prevCollapsedSections = loaded.collapsedSections;
    } else {
      prevSelectedDay = 0;
      prevCollapsedSections = {};
    }

    final results = await Future.wait([
      _tripRepository.getTripById(tripId),
      _activityRepository.getActivities(tripId),
      _transportRepository.getManualFlights(tripId),
      _accommodationRepository.getByTrip(tripId),
      _baggageRepository.getByTrip(tripId),
      _budgetRepository.getBudgetSummary(tripId),
      _budgetRepository.getBudgetItems(tripId),
      _tripShareRepository.getSharesByTrip(tripId),
    ]);

    if (isClosed) return;

    final tripResult = results[0] as Result<Trip>;
    final activitiesResult = results[1] as Result<List<Activity>>;
    final flightsResult = results[2] as Result<List<ManualFlight>>;
    final accommodationsResult = results[3] as Result<List<Accommodation>>;
    final baggageResult = results[4] as Result<List<BaggageItem>>;
    final budgetResult = results[5] as Result<BudgetSummary>;
    final budgetItemsResult = results[6] as Result<List<BudgetItem>>;
    final sharesResult = results[7] as Result<List<TripShare>>;

    final Trip trip;
    switch (tripResult) {
      case Success(:final data):
        trip = data;
      case Failure(:final error):
        emit(TripDetailError(error: error));
        return;
    }
    final activities = activitiesResult.dataOrNull ?? [];
    final sectionErrors = <String, AppError>{};

    final flights = switch (flightsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['flights'] = error;
        return <ManualFlight>[];
      }(),
    };
    final accommodations = switch (accommodationsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['accommodations'] = error;
        return <Accommodation>[];
      }(),
    };
    final baggageItems = switch (baggageResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['baggage'] = error;
        return <BaggageItem>[];
      }(),
    };
    final BudgetSummary? budgetSummary = switch (budgetResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['budget'] = error;
        return null;
      }(),
    };
    final budgetItems = switch (budgetItemsResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['budget'] = error;
        return <BudgetItem>[];
      }(),
    };
    final shares = switch (sharesResult) {
      Success(:final data) => data,
      Failure(:final error) => () {
        sectionErrors['shares'] = error;
        return <TripShare>[];
      }(),
    };

    final completion = tripDetailCompletion(
      trip: trip,
      flights: flights,
      accommodations: accommodations,
      activities: activities,
      baggageItems: baggageItems,
    );

    emit(
      TripDetailLoaded(
        trip: trip,
        activities: activities,
        flights: flights,
        accommodations: accommodations,
        baggageItems: baggageItems,
        budgetSummary: budgetSummary,
        budgetItems: budgetItems,
        shares: shares,
        selectedDayIndex: prevSelectedDay,
        userRole: trip.role ?? 'OWNER',
        completionResult: completion,
        collapsedSections: prevCollapsedSections,
        deferredLoaded: true,
        sectionErrors: sectionErrors,
      ),
    );
  }

  void _onSelectDay(SelectDay event, Emitter<TripDetailState> emit) {
    if (state is! TripDetailLoaded) return;
    emit(
      (state as TripDetailLoaded).copyWith(selectedDayIndex: event.dayIndex),
    );
  }

  void _onToggleSection(ToggleSection event, Emitter<TripDetailState> emit) {
    if (state is! TripDetailLoaded) return;
    final loaded = state as TripDetailLoaded;
    final sections = Set<String>.from(loaded.collapsedSections);
    if (sections.contains(event.sectionId)) {
      sections.remove(event.sectionId);
    } else {
      sections.add(event.sectionId);
    }
    emit(loaded.copyWith(collapsedSections: sections));
  }

  Future<void> _onRetryDeferredSection(
    RetryDeferredSection event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final section = event.section;

    switch (section) {
      case 'flights':
        final result = await _transportRepository.getManualFlights(_tripId!);
        if (isClosed || state is! TripDetailLoaded) return;
        if (result case Success(:final data)) {
          final current = state as TripDetailLoaded;
          emit(
            current.copyWith(
              flights: data,
              sectionErrors: _clearSectionError(current, section),
            ),
          );
        }
      case 'accommodations':
        final result = await _accommodationRepository.getByTrip(_tripId!);
        if (isClosed || state is! TripDetailLoaded) return;
        if (result case Success(:final data)) {
          final current = state as TripDetailLoaded;
          emit(
            current.copyWith(
              accommodations: data,
              sectionErrors: _clearSectionError(current, section),
            ),
          );
        }
      case 'baggage':
        final result = await _baggageRepository.getByTrip(_tripId!);
        if (isClosed || state is! TripDetailLoaded) return;
        if (result case Success(:final data)) {
          final current = state as TripDetailLoaded;
          emit(
            current.copyWith(
              baggageItems: data,
              sectionErrors: _clearSectionError(current, section),
            ),
          );
        }
      case 'budget':
        final results = await Future.wait([
          _budgetRepository.getBudgetSummary(_tripId!),
          _budgetRepository.getBudgetItems(_tripId!),
        ]);
        if (isClosed || state is! TripDetailLoaded) return;
        final summaryResult = results[0] as Result<BudgetSummary>;
        final itemsResult = results[1] as Result<List<BudgetItem>>;
        if (summaryResult case Success(:final data)) {
          final current = state as TripDetailLoaded;
          emit(
            current.copyWith(
              budgetSummary: data,
              budgetItems: itemsResult.dataOrNull ?? current.budgetItems,
              sectionErrors: _clearSectionError(current, section),
            ),
          );
        }
      case 'shares':
        final result = await _tripShareRepository.getSharesByTrip(_tripId!);
        if (isClosed || state is! TripDetailLoaded) return;
        if (result case Success(:final data)) {
          final current = state as TripDetailLoaded;
          emit(
            current.copyWith(
              shares: data,
              sectionErrors: _clearSectionError(current, section),
            ),
          );
        }
    }
  }

  Map<String, AppError> _clearSectionError(
    TripDetailLoaded current,
    String section,
  ) => Map<String, AppError>.from(current.sectionErrors)..remove(section);
}
