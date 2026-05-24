import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bloc/bloc.dart';

part 'post_trip_event.dart';
part 'post_trip_state.dart';

class PostTripBloc extends Bloc<PostTripEvent, PostTripState> {
  final TripRepository _tripRepository;
  final ActivityRepository _activityRepository;
  final BudgetRepository _budgetRepository;

  PostTripBloc({
    TripRepository? tripRepository,
    ActivityRepository? activityRepository,
    BudgetRepository? budgetRepository,
  }) : _tripRepository = tripRepository ?? getIt<TripRepository>(),
       _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
       _budgetRepository = budgetRepository ?? getIt<BudgetRepository>(),
       super(PostTripInitial()) {
    on<LoadPostTripStats>(_onLoadPostTripStats);
  }

  Future<void> _onLoadPostTripStats(
    LoadPostTripStats event,
    Emitter<PostTripState> emit,
  ) async {
    emit(PostTripLoading());

    final results = await Future.wait([
      _tripRepository.getTripById(event.tripId),
      _activityRepository.getActivities(event.tripId),
      _budgetRepository.getBudgetSummary(event.tripId),
    ]);

    if (isClosed) return;

    final tripResult = results[0] as Result<Trip>;
    final activitiesResult = results[1] as Result<List<Activity>>;
    final budgetResult = results[2] as Result<BudgetSummary>;

    final Trip trip;
    switch (tripResult) {
      case Success(:final data):
        trip = data;
      case Failure(:final error):
        emit(PostTripError(error: error));
        return;
    }

    // Compute stats
    final activities = activitiesResult is Success<List<Activity>>
        ? activitiesResult.data
        : <Activity>[];

    final activitiesCompleted = activities.where((a) => a.isDone).length;

    final categoriesExplored = activities.map((a) => a.category).toSet();

    final hasAiActivities = activities.any(
      (a) => a.validationStatus == ValidationStatus.suggested,
    );

    double budgetSpent = 0;
    double budgetTotal = 0;
    if (budgetResult is Success<BudgetSummary>) {
      budgetSpent = budgetResult.data.totalSpent;
      budgetTotal = budgetResult.data.totalBudget;
    }

    int totalDays = 1;
    final start = trip.startDate;
    final end = trip.endDate;
    if (start != null && end != null) {
      final diff = DateTime(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays;
      totalDays = diff < 1 ? 1 : diff + 1;
    }

    emit(
      PostTripLoaded(
        trip: trip,
        totalDays: totalDays,
        activitiesCompleted: activitiesCompleted,
        totalActivities: activities.length,
        budgetSpent: budgetSpent,
        budgetTotal: budgetTotal,
        destinationName: trip.destinationName ?? trip.title ?? '',
        categoriesExplored: categoriesExplored,
        hasAiActivities: hasAiActivities,
      ),
    );
  }
}
