import 'package:bagtrip/service/api_client.dart';

class AgentService {
  final ApiClient _apiClient;

  AgentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Chat with the agent (SSE streaming).
  /// TODO: Implement in Epic 6.
  Stream<Map<String, dynamic>> chat({
    required String tripId,
    required String conversationId,
    required String message,
    int? contextVersion,
  }) {
    throw UnimplementedError('Chat SSE will be implemented in Epic 6');
  }

  /// Quick action (SELECT/BOOK).
  /// TODO: Implement in Epic 6.
  Future<Map<String, dynamic>> action({
    required String tripId,
    required String conversationId,
    required Map<String, dynamic> action,
    int? contextVersion,
  }) async {
    try {
      final response = await _apiClient.post(
        '/agent/actions',
        data: {
          'tripId': tripId,
          'conversationId': conversationId,
          'action': action,
          if (contextVersion != null) 'contextVersion': contextVersion,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to execute action: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error executing action: $e');
    }
  }
}
