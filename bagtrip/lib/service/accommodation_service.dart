import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/service/api_client.dart';

class AccommodationService {
  final ApiClient _apiClient;

  AccommodationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Create an accommodation for a trip.
  Future<Accommodation> createAccommodation(
    String tripId, {
    required String name,
    String? address,
    DateTime? checkIn,
    DateTime? checkOut,
    double? price,
    String? currency,
    String? bookingReference,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/accommodations',
        data: {
          'name': name,
          if (address != null) 'address': address,
          if (checkIn != null)
            'checkIn': checkIn.toIso8601String().split('T').first,
          if (checkOut != null)
            'checkOut': checkOut.toIso8601String().split('T').first,
          if (price != null) 'price': price,
          if (currency != null) 'currency': currency,
          if (bookingReference != null) 'bookingReference': bookingReference,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Accommodation.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create accommodation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating accommodation: $e');
    }
  }

  /// Get all accommodations for a trip.
  Future<List<Accommodation>> getByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/accommodations');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Accommodation.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Accommodation.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception(
          'Failed to fetch accommodations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching accommodations: $e');
    }
  }

  /// Update an accommodation.
  Future<Accommodation> updateAccommodation(
    String tripId,
    String accommodationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/accommodations/$accommodationId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Accommodation.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to update accommodation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating accommodation: $e');
    }
  }

  /// Delete an accommodation.
  Future<void> deleteAccommodation(
    String tripId,
    String accommodationId,
  ) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/accommodations/$accommodationId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete accommodation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting accommodation: $e');
    }
  }
}
