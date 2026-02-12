import 'package:bagtrip/service/api_client.dart';

class MessageService {
  final ApiClient _apiClient;

  MessageService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Get messages for a conversation.
  Future<List<MessageModel>> getMessagesByConversation(
    String conversationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final items = data['items'] as List<dynamic>? ?? data as List<dynamic>;
        return items
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  /// Create a message.
  Future<MessageModel> createMessage(
    String conversationId, {
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.post(
        '/conversations/$conversationId/messages',
        data: {
          'role': role,
          'content': content,
          if (metadata != null) 'message_metadata': metadata,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return MessageModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating message: $e');
    }
  }
}

/// Message model for the service layer.
class MessageModel {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? messageMetadata;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.messageMetadata,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId:
          json['conversationId'] as String? ??
          json['conversation_id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      messageMetadata: json['message_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      if (messageMetadata != null) 'message_metadata': messageMetadata,
    };
  }
}
