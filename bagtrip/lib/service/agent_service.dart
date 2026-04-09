import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class AgentService {
  final ApiClient _apiClient;

  AgentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Chat with the agent (SSE streaming).
  /// BLOCKED: Requires SSE infrastructure (Epic 6).
  Stream<Map<String, dynamic>> chat({
    required String tripId,
    required String conversationId,
    required String message,
    int? contextVersion,
  }) {
    throw UnimplementedError('Chat SSE will be implemented in Epic 6');
  }

  /// Quick action (SELECT/BOOK).
  Future<Result<Map<String, dynamic>>> action({
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
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Success(data);
        }
        return loggedFailure(
          ServerError(
            'Unexpected response format',
            statusCode: response.statusCode,
          ),
        );
      } else {
        return loggedFailure(
          ServerError(
            'Failed to execute action: ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      }
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(
        UnknownError('Error executing action: $e', originalError: e),
      );
    }
  }
}
