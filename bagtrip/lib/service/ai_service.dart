import 'package:bagtrip/service/api_client.dart';

class AiService {
  final ApiClient _apiClient;

  AiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get AI trip inspiration.
  Future<List<Map<String, dynamic>>> getInspiration({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/inspire',
        data: {
          if (travelTypes != null) 'travelTypes': travelTypes,
          if (budgetRange != null) 'budgetRange': budgetRange,
          if (durationDays != null) 'durationDays': durationDays,
          if (companions != null) 'companions': companions,
          if (season != null) 'season': season,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestions'] is List) {
          return (data['suggestions'] as List)
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to get AI inspiration: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting AI inspiration: $e');
    }
  }

  /// Accept an AI suggestion and create a DRAFT trip.
  Future<Map<String, dynamic>> acceptInspiration(
    Map<String, dynamic> suggestion,
  ) async {
    try {
      final response = await _apiClient.post(
        '/ai/inspire/accept',
        data: {'suggestion': suggestion},
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      } else {
        throw Exception('Failed to accept inspiration: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error accepting inspiration: $e');
    }
  }
}
