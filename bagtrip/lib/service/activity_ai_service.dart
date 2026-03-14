import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class ActivityAiService {
  final ApiClient _apiClient;

  ActivityAiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Suggest activities for a trip via AI.
  Future<List<Map<String, dynamic>>> suggestActivities(String tripId) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/activities/suggest',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['activities'] is List) {
          return (data['activities'] as List)
              .map((a) => Map<String, dynamic>.from(a))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to get AI suggestions: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting AI activity suggestions: $e');
    }
  }
}
