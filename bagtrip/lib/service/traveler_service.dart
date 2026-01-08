import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/service/api_client.dart';

class TravelerService {
  final ApiClient _apiClient;

  TravelerService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Créer un traveler pour un trip
  Future<Traveler> createTraveler(
    String tripId, {
    String? amadeusTravelerRef,
    required String travelerType,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    List<Map<String, dynamic>>? documents,
    Map<String, dynamic>? contacts,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/travelers',
        data: {
          if (amadeusTravelerRef != null)
            'amadeusTravelerRef': amadeusTravelerRef,
          'travelerType': travelerType,
          'firstName': firstName,
          'lastName': lastName,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (documents != null) 'documents': documents,
          if (contacts != null) 'contacts': contacts,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Traveler.fromJson(response.data);
      } else {
        throw Exception('Failed to create traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating traveler: $e');
    }
  }

  /// Récupérer tous les travelers d'un trip
  Future<List<Traveler>> getTravelersByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/travelers');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Traveler.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Traveler.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to fetch travelers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching travelers: $e');
    }
  }

  /// Mettre à jour un traveler
  Future<Traveler> updateTraveler(
    String tripId,
    String travelerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/travelers/$travelerId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return Traveler.fromJson(response.data);
      } else {
        throw Exception('Failed to update traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating traveler: $e');
    }
  }

  /// Supprimer un traveler
  Future<void> deleteTraveler(String tripId, String travelerId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/travelers/$travelerId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete traveler: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting traveler: $e');
    }
  }
}
