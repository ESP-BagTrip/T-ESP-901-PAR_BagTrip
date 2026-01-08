import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/service/api_client.dart';

class TripService {
  final ApiClient _apiClient;

  TripService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Créer un nouveau trip
  Future<Trip> createTrip({
    required String title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips',
        data: {
          'title': title,
          if (originIata != null) 'originIata': originIata,
          if (destinationIata != null) 'destinationIata': destinationIata,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to create trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating trip: $e');
    }
  }

  /// Récupérer tous les trips de l'utilisateur
  Future<List<Trip>> getTrips() async {
    try {
      final response = await _apiClient.get('/trips');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Trip.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Trip.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trips: $e');
    }
  }

  /// Récupérer un trip par ID
  Future<Trip> getTripById(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle TripDetailResponse which has a 'trip' field
        if (data is Map && data['trip'] != null) {
          return Trip.fromJson(data['trip'] as Map<String, dynamic>);
        }
        return Trip.fromJson(data);
      } else {
        throw Exception('Failed to fetch trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trip: $e');
    }
  }

  /// Mettre à jour un trip
  Future<Trip> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.patch('/trips/$tripId', data: updates);

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to update trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating trip: $e');
    }
  }

  /// Supprimer un trip
  Future<void> deleteTrip(String tripId) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting trip: $e');
    }
  }
}
