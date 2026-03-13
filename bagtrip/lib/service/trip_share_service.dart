import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/service/api_client.dart';

class TripShareService {
  final ApiClient _apiClient;

  TripShareService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Invite a user by email to share a trip.
  Future<TripShare> createShare(String tripId, {required String email}) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/shares',
        data: {'email': email},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TripShare.fromJson(response.data);
      } else {
        throw Exception('Failed to create share: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating share: $e');
    }
  }

  /// Get all shares for a trip.
  Future<List<TripShare>> getSharesByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/shares');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => TripShare.fromJson(json))
              .toList();
        }
        if (data is List) {
          return data.map((json) => TripShare.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch shares: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shares: $e');
    }
  }

  /// Revoke a share.
  Future<void> deleteShare(String tripId, String shareId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/shares/$shareId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete share: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting share: $e');
    }
  }
}
