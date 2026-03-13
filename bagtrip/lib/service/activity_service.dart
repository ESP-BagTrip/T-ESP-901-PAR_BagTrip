import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/service/api_client.dart';

class ActivityService {
  final ApiClient _apiClient;

  ActivityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get all activities for a trip.
  Future<List<Activity>> getActivities(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/activities');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Activity.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Activity.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching activities: $e');
    }
  }

  /// Create an activity for a trip.
  Future<Activity> createActivity(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/activities',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Activity.fromJson(response.data);
      } else {
        throw Exception('Failed to create activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating activity: $e');
    }
  }

  /// Update an activity.
  Future<Activity> updateActivity(
    String tripId,
    String activityId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/activities/$activityId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Activity.fromJson(response.data);
      } else {
        throw Exception('Failed to update activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  /// Delete an activity.
  Future<void> deleteActivity(String tripId, String activityId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/activities/$activityId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }
}
