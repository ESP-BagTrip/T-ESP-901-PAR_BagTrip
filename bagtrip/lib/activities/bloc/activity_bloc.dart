import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/service/activity_service.dart';
import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';

part 'activity_event.dart';
part 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityService _activityService;

  ActivityBloc({ActivityService? activityService})
    : _activityService = activityService ?? ActivityService(),
      super(ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<CreateActivity>(_onCreateActivity);
    on<UpdateActivity>(_onUpdateActivity);
    on<DeleteActivity>(_onDeleteActivity);
  }

  Map<String, List<Activity>> _groupByDay(List<Activity> activities) {
    final Map<String, List<Activity>> grouped = {};
    for (final activity in activities) {
      final key = DateFormat('yyyy-MM-dd').format(activity.date);
      grouped.putIfAbsent(key, () => []).add(activity);
    }
    // Sort activities within each day by startTime
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
    try {
      final activities = await _activityService.getActivities(event.tripId);
      emit(
        ActivitiesLoaded(
          activities: activities,
          groupedByDay: _groupByDay(activities),
        ),
      );
    } catch (e) {
      emit(ActivityError(message: e.toString()));
    }
  }

  Future<void> _onCreateActivity(
    CreateActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.createActivity(event.tripId, event.data);
      add(LoadActivities(tripId: event.tripId));
    } catch (e) {
      emit(ActivityError(message: e.toString()));
    }
  }

  Future<void> _onUpdateActivity(
    UpdateActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.updateActivity(
        event.tripId,
        event.activityId,
        event.data,
      );
      add(LoadActivities(tripId: event.tripId));
    } catch (e) {
      emit(ActivityError(message: e.toString()));
    }
  }

  Future<void> _onDeleteActivity(
    DeleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.deleteActivity(event.tripId, event.activityId);
      add(LoadActivities(tripId: event.tripId));
    } catch (e) {
      emit(ActivityError(message: e.toString()));
    }
  }
}
