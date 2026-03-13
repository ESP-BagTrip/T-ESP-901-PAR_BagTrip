import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/service/api_client.dart';

class BaggageItemService {
  final ApiClient _apiClient;

  BaggageItemService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Create a baggage item for a trip.
  Future<BaggageItem> createBaggageItem(
    String tripId, {
    required String name,
    int? quantity,
    bool? isPacked,
    String? category,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/baggage',
        data: {
          'name': name,
          if (quantity != null) 'quantity': quantity,
          if (isPacked != null) 'isPacked': isPacked,
          if (category != null) 'category': category,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BaggageItem.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to create baggage item: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating baggage item: $e');
    }
  }

  /// Get all baggage items for a trip.
  Future<List<BaggageItem>> getByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/baggage');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => BaggageItem.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => BaggageItem.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception(
          'Failed to fetch baggage items: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching baggage items: $e');
    }
  }

  /// Update a baggage item.
  Future<BaggageItem> updateBaggageItem(
    String tripId,
    String baggageItemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/baggage/$baggageItemId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return BaggageItem.fromJson(response.data);
      } else {
        throw Exception(
          'Failed to update baggage item: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating baggage item: $e');
    }
  }

  /// Delete a baggage item.
  Future<void> deleteBaggageItem(String tripId, String baggageItemId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/baggage/$baggageItemId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete baggage item: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting baggage item: $e');
    }
  }
}
