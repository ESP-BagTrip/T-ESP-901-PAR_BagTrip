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
import 'package:bloc/bloc.dart';

part 'trip_detail_event.dart';
part 'trip_detail_state.dart';

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
    on<LoadTripDetail>(_onLoadTripDetail);
    on<RefreshTripDetail>(_onRefreshTripDetail);
    on<SelectDay>(_onSelectDay);
    on<ToggleSection>(_onToggleSection);
    on<ValidateActivity>(_onValidateActivity);
    on<RejectActivity>(_onRejectActivity);
    on<UpdateTripStatus>(_onUpdateTripStatus);
    on<DeleteTripDetail>(_onDeleteTrip);
    on<DeleteFlightFromDetail>(_onDeleteFlight);
    on<DeleteAccommodationFromDetail>(_onDeleteAccommodation);
  }

  Future<void> _onLoadTripDetail(
    LoadTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    _tripId = event.tripId;
    emit(TripDetailLoading());
    await _fetchAll(event.tripId, emit);
  }

  Future<void> _onRefreshTripDetail(
    RefreshTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;
    await _fetchAll(_tripId!, emit, preserveUiState: true);
  }

  Future<void> _fetchAll(
    String tripId,
    Emitter<TripDetailState> emit, {
    bool preserveUiState = false,
  }) async {
    // Preserve UI state from current loaded state if requested
    final int prevSelectedDay;
    final Set<String> prevCollapsedSections;
    if (preserveUiState && state is TripDetailLoaded) {
      final loaded = state as TripDetailLoaded;
      prevSelectedDay = loaded.selectedDayIndex;
      prevCollapsedSections = loaded.collapsedSections;
    } else {
      prevSelectedDay = 0;
      prevCollapsedSections = {};
    }

    final results = await Future.wait([
      _tripRepository.getTripById(tripId), // 0 — mandatory
      _activityRepository.getActivities(tripId), // 1
      _transportRepository.getManualFlights(tripId), // 2
      _accommodationRepository.getByTrip(tripId), // 3
      _baggageRepository.getByTrip(tripId), // 4
      _budgetRepository.getBudgetSummary(tripId), // 5
      _tripShareRepository.getSharesByTrip(tripId), // 6
    ]);

    if (isClosed) return;

    final tripResult = results[0] as Result<Trip>;
    final activitiesResult = results[1] as Result<List<Activity>>;
    final flightsResult = results[2] as Result<List<ManualFlight>>;
    final accommodationsResult = results[3] as Result<List<Accommodation>>;
    final baggageResult = results[4] as Result<List<BaggageItem>>;
    final budgetResult = results[5] as Result<BudgetSummary>;
    final sharesResult = results[6] as Result<List<TripShare>>;

    // Trip is mandatory — failure → error
    if (tripResult is Failure<Trip>) {
      emit(TripDetailError(error: tripResult.error));
      return;
    }

    final trip = (tripResult as Success<Trip>).data;

    // Optional data — fallback to empty on failure
    final activities = activitiesResult.dataOrNull ?? [];
    final flights = flightsResult.dataOrNull ?? [];
    final accommodations = accommodationsResult.dataOrNull ?? [];
    final baggageItems = baggageResult.dataOrNull ?? [];
    final budgetSummary = budgetResult.dataOrNull;
    final shares = sharesResult.dataOrNull ?? [];

    final completion = tripDetailCompletion(
      trip: trip,
      flights: flights,
      accommodations: accommodations,
      activities: activities,
      baggageItems: baggageItems,
      budgetSummary: budgetSummary,
    );

    emit(
      TripDetailLoaded(
        trip: trip,
        activities: activities,
        flights: flights,
        accommodations: accommodations,
        baggageItems: baggageItems,
        budgetSummary: budgetSummary,
        shares: shares,
        selectedDayIndex: prevSelectedDay,
        userRole: trip.role ?? 'OWNER',
        completionResult: completion,
        collapsedSections: prevCollapsedSections,
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

  Future<void> _onValidateActivity(
    ValidateActivity event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update
    final updatedActivities = loaded.activities.map((a) {
      if (a.id == event.activityId) {
        return Activity(
          id: a.id,
          tripId: a.tripId,
          title: a.title,
          description: a.description,
          date: a.date,
          startTime: a.startTime,
          endTime: a.endTime,
          location: a.location,
          category: a.category,
          estimatedCost: a.estimatedCost,
          isBooked: a.isBooked,
          validationStatus: ValidationStatus.validated,
          suggestedDay: a.suggestedDay,
          createdAt: a.createdAt,
          updatedAt: a.updatedAt,
        );
      }
      return a;
    }).toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.updateActivity(
      _tripId!,
      event.activityId,
      {'validation_status': 'VALIDATED'},
    );

    if (isClosed) return;

    if (result is Failure) {
      // Rollback
      emit(loaded);
    }
  }

  Future<void> _onRejectActivity(
    RejectActivity event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic update — remove rejected activity
    final updatedActivities = loaded.activities
        .where((a) => a.id != event.activityId)
        .toList();
    emit(loaded.copyWith(activities: updatedActivities));

    final result = await _activityRepository.deleteActivity(
      _tripId!,
      event.activityId,
    );

    if (isClosed) return;

    if (result is Failure) {
      // Rollback
      emit(loaded);
    }
  }

  Future<void> _onUpdateTripStatus(
    UpdateTripStatus event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;

    final result = await _tripRepository.updateTripStatus(
      _tripId!,
      event.status,
    );

    if (isClosed) return;

    if (result is Success) {
      add(RefreshTripDetail());
    }
  }

  Future<void> _onDeleteFlight(
    DeleteFlightFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedFlights = loaded.flights
        .where((f) => f.id != event.flightId)
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: updatedFlights,
      accommodations: loaded.accommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
      budgetSummary: loaded.budgetSummary,
    );
    emit(
      loaded.copyWith(flights: updatedFlights, completionResult: completion),
    );

    final result = await _transportRepository.deleteManualFlight(
      _tripId!,
      event.flightId,
    );

    if (isClosed) return;

    if (result is Failure) {
      // Rollback
      emit(loaded);
    }
  }

  Future<void> _onDeleteAccommodation(
    DeleteAccommodationFromDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (state is! TripDetailLoaded || _tripId == null) return;
    final loaded = state as TripDetailLoaded;

    // Optimistic removal
    final updatedAccommodations = loaded.accommodations
        .where((a) => a.id != event.accommodationId)
        .toList();
    final completion = tripDetailCompletion(
      trip: loaded.trip,
      flights: loaded.flights,
      accommodations: updatedAccommodations,
      activities: loaded.activities,
      baggageItems: loaded.baggageItems,
      budgetSummary: loaded.budgetSummary,
    );
    emit(
      loaded.copyWith(
        accommodations: updatedAccommodations,
        completionResult: completion,
      ),
    );

    final result = await _accommodationRepository.deleteAccommodation(
      _tripId!,
      event.accommodationId,
    );

    if (isClosed) return;

    if (result is Failure) {
      // Rollback
      emit(loaded);
    }
  }

  Future<void> _onDeleteTrip(
    DeleteTripDetail event,
    Emitter<TripDetailState> emit,
  ) async {
    if (_tripId == null) return;

    final result = await _tripRepository.deleteTrip(_tripId!);

    if (isClosed) return;

    if (result is Success) {
      emit(TripDetailDeleted());
    }
  }

  @override
  // ignore: unnecessary_overrides
  Future<void> close() {
    return super.close();
  }
}
