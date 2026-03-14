import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class PostTripAiService {
  final ApiClient _apiClient;

  PostTripAiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get post-trip suggestion based on feedback history.
  Future<Map<String, dynamic>> getPostTripSuggestion() async {
    try {
      final response = await _apiClient.post('/ai/post-trip-suggestion');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestion'] != null) {
          return Map<String, dynamic>.from(data['suggestion']);
        }
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(
          'Failed to get post-trip suggestion: ${response.statusCode}',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Error getting post-trip suggestion: $e');
    }
  }
}
