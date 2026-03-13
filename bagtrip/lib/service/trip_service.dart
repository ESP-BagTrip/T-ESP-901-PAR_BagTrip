import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/service/api_client.dart';

class TripService {
  final ApiClient _apiClient;

  TripService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create a new trip.
  Future<Trip> createTrip({
    required String title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? destinationName,
    int? nbTravelers,
    String? coverImageUrl,
    double? budgetTotal,
    String? origin,
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
          if (description != null) 'description': description,
          if (destinationName != null) 'destinationName': destinationName,
          if (nbTravelers != null) 'nbTravelers': nbTravelers,
          if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
          if (budgetTotal != null) 'budgetTotal': budgetTotal,
          if (origin != null) 'origin': origin,
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

  /// Get all trips for the current user.
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

  /// Get trips grouped by status.
  Future<TripGrouped> getGroupedTrips() async {
    try {
      final response = await _apiClient.get('/trips/grouped');

      if (response.statusCode == 200) {
        return TripGrouped.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to fetch grouped trips: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching grouped trips: $e');
    }
  }

  /// Get trip home page data.
  Future<TripHome> getTripHome(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/home');

      if (response.statusCode == 200) {
        return TripHome.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch trip home: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trip home: $e');
    }
  }

  /// Update trip status.
  Future<Trip> updateTripStatus(String tripId, String status) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to update trip status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating trip status: $e');
    }
  }

  /// Get a trip by ID.
  Future<Trip> getTripById(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');

      if (response.statusCode == 200) {
        final data = response.data;
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

  /// Update a trip.
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

  /// Delete a trip.
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
