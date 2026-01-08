import 'package:equatable/equatable.dart';
import 'package:bagtrip/chat/models/context.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Chargement de l'historique
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Chat chargé avec messages et contexte
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final ChatContext? context;
  final bool isStreaming;
  final String? streamingText;
  final String? activeTool;
  final String? error;

  const ChatLoaded({
    required this.messages,
    this.context,
    this.isStreaming = false,
    this.streamingText,
    this.activeTool,
    this.error,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    ChatContext? context,
    bool? isStreaming,
    Object? streamingText = _undefined,
    Object? activeTool = _undefined,
    Object? error = _undefined,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText:
          streamingText == _undefined
              ? this.streamingText
              : streamingText as String?,
      activeTool:
          activeTool == _undefined ? this.activeTool : activeTool as String?,
      error: error == _undefined ? this.error : error as String?,
    );
  }

  static const _undefined = Object();

  @override
  List<Object?> get props => [
    messages,
    context,
    isStreaming,
    streamingText,
    activeTool,
    error,
  ];
}

/// Erreur
class ChatError extends ChatState {
  final String message;
  final bool shouldRefreshContext;

  const ChatError(this.message, {this.shouldRefreshContext = false});

  @override
  List<Object?> get props => [message, shouldRefreshContext];
}

/// Modèle de message de chat
class ChatMessage {
  final String id;
  final String role; // "user" | "assistant" | "tool"
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? json['created_at'] as String,
      ),
      metadata: json['message_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      if (metadata != null) 'message_metadata': metadata,
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isTool => role == 'tool';
}
