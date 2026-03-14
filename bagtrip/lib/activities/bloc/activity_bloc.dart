import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/utils/error_display.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository _activityRepository;

  ActivityBloc({ActivityRepository? activityRepository})
    : _activityRepository = activityRepository ?? getIt<ActivityRepository>(),
      super(ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<CreateActivity>(_onCreateActivity);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
    on<SuggestActivities>(_onSuggestActivities);
    on<AddSuggestedActivity>(_onAddSuggestedActivity);
  }

  Map<String, List<Activity>> _groupByDay(List<Activity> activities) {
    final Map<String, List<Activity>> grouped = {};
    for (final activity in activities) {
      final key = DateFormat('yyyy-MM-dd').format(activity.date);
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    for (final list in grouped.values) {
      list.sort((a, b) {
        final aTime = a.startTime ?? '';
        final bTime = b.startTime ?? '';
        return aTime.compareTo(bTime);
      });
    }
    return grouped;
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    final result = await _activityRepository.getActivities(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          ActivitiesLoaded(activities: data, groupedByDay: _groupByDay(data)),
        );
      case Failure(:final error):
        emit(ActivityError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onCreateActivity(
    CreateActivity event,
    Emitter<ActivityState> emit,
  ) async {
    final result = await _activityRepository.createActivity(
      event.tripId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadActivities(tripId: event.tripId));
      case Failure(:final error):
        emit(ActivityError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onUpdateActivity(
    UpdateActivity event,
    Emitter<ActivityState> emit,
  ) async {
    final result = await _activityRepository.updateActivity(
      event.tripId,
      event.activityId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadActivities(tripId: event.tripId));
      case Failure(:final error):
        emit(ActivityError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    final result = await _activityRepository.deleteActivity(
      event.tripId,
      event.activityId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadActivities(tripId: event.tripId));
      case Failure(:final error):
        emit(ActivityError(message: toUserFriendlyMessage(error)));
    }
  }

  Future<void> _onSuggestActivities(
    SuggestActivities event,
    Emitter<ActivityState> emit,
  ) async {
    // Preserve current activities if available
    List<Activity> currentActivities = [];
    Map<String, List<Activity>> currentGrouped = {};
    if (state is ActivitiesLoaded) {
      currentActivities = (state as ActivitiesLoaded).activities;
      currentGrouped = (state as ActivitiesLoaded).groupedByDay;
    }

    emit(ActivitySuggestionsLoading());
    final result = await _activityRepository.suggestActivities(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          ActivitySuggestionsLoaded(
            suggestions: data,
            activities: currentActivities,
            groupedByDay: currentGrouped,
          ),
        );
      case Failure(:final error):
        if (error is QuotaExceededError) {
          emit(
            ActivitiesLoaded(
              activities: currentActivities,
              groupedByDay: currentGrouped,
            ),
          );
          emit(ActivityQuotaExceeded());
        } else {
          emit(ActivityError(message: toUserFriendlyMessage(error)));
        }
    }
  }

  Future<void> _onAddSuggestedActivity(
    AddSuggestedActivity event,
    Emitter<ActivityState> emit,
  ) async {
    final result = await _activityRepository.createActivity(
      event.tripId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadActivities(tripId: event.tripId));
      case Failure(:final error):
        emit(ActivityError(message: toUserFriendlyMessage(error)));
    }
  }
}
