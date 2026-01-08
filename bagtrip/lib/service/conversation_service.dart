import 'package:bagtrip/models/conversation.dart';
import 'package:bagtrip/service/api_client.dart';

class ConversationService {
  final ApiClient _apiClient;

  ConversationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Créer une conversation pour un trip
  Future<Conversation> createConversation(
    String tripId, {
    String? title,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/conversations',
        data: {if (title != null) 'title': title},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        // Handle response format: { "conversation": {...} }
        if (data is Map && data['conversation'] != null) {
          return Conversation.fromJson(
            data['conversation'] as Map<String, dynamic>,
          );
        }
        return Conversation.fromJson(data);
      } else {
        throw Exception(
          'Failed to create conversation: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  /// Récupérer toutes les conversations d'un trip
  Future<List<Conversation>> getConversationsByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/conversations');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data.map((json) => Conversation.fromJson(json)).toList();
        } else if (data is Map && data['items'] is List) {
          return (data['items'] as List)
              .map((json) => Conversation.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception(
          'Failed to fetch conversations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching conversations: $e');
    }
  }

  /// Récupérer une conversation par ID
  Future<Conversation> getConversationById(String conversationId) async {
    try {
      final response = await _apiClient.get('/conversations/$conversationId');

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle response format: { "conversation": {...} }
        if (data is Map && data['conversation'] != null) {
          return Conversation.fromJson(
            data['conversation'] as Map<String, dynamic>,
          );
        }
        return Conversation.fromJson(data);
      } else {
        throw Exception('Failed to fetch conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }
}
