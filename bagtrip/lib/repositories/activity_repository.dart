import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';

abstract class ActivityRepository {
  Future<Result<List<Activity>>> getActivities(String tripId);
  Future<Result<Activity>> createActivity(
    String tripId,
    Map<String, dynamic> data,
  );
  Future<Result<Activity>> updateActivity(
    String tripId,
    String activityId,
    Map<String, dynamic> updates,
  );
  Future<Result<void>> deleteActivity(String tripId, String activityId);
  Future<Result<List<Map<String, dynamic>>>> suggestActivities(String tripId);
}
