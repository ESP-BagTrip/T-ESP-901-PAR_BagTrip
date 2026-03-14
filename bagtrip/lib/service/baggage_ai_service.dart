import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class BaggageAiService {
  final ApiClient _apiClient;

  BaggageAiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Suggest baggage items for a trip via AI.
  Future<List<Map<String, dynamic>>> suggestBaggage(String tripId) async {
    try {
      final response = await _apiClient.post('/trips/$tripId/baggage/suggest');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(
          'Failed to get AI baggage suggestions: ${response.statusCode}',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting AI baggage suggestions: $e');
    }
  }
}
