import 'dart:convert';

/// Événement de base pour tous les événements SSE
abstract class SSEEvent {
  final String eventType;
  final Map<String, dynamic> data;

  SSEEvent({required this.eventType, required this.data});

  factory SSEEvent.fromSSE(String eventType, String data) {
    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;

      switch (eventType) {
        case 'message.delta':
          return MessageDeltaEvent.fromJson(jsonData);
        case 'message.final':
          return MessageFinalEvent.fromJson(jsonData);
        case 'context.updated':
          return ContextUpdatedEvent.fromJson(jsonData);
        case 'tool.start':
          return ToolStartEvent.fromJson(jsonData);
        case 'tool.end':
          return ToolEndEvent.fromJson(jsonData);
        case 'error':
          return ErrorEvent.fromJson(jsonData);
        default:
          return UnknownEvent(eventType: eventType, data: jsonData);
      }
    } catch (e) {
      // Si le parsing JSON échoue, retourner un ErrorEvent
      return ErrorEvent(
        message: 'Failed to parse SSE event: $e',
        code: 'PARSE_ERROR',
      );
    }
  }
}

/// Événement : delta de texte en streaming
class MessageDeltaEvent extends SSEEvent {
  final String text;

  MessageDeltaEvent({required this.text})
    : super(eventType: 'message.delta', data: {'text': text});

  factory MessageDeltaEvent.fromJson(Map<String, dynamic> json) {
    return MessageDeltaEvent(text: json['text'] as String);
  }
}

/// Événement : message final avec ID
class MessageFinalEvent extends SSEEvent {
  final String messageId;
  final String text;

  MessageFinalEvent({required this.messageId, required this.text})
    : super(
        eventType: 'message.final',
        data: {'message_id': messageId, 'text': text},
      );

  factory MessageFinalEvent.fromJson(Map<String, dynamic> json) {
    return MessageFinalEvent(
      messageId: json['message_id'] as String,
      text: json['text'] as String,
    );
  }
}

/// Événement : contexte mis à jour
class ContextUpdatedEvent extends SSEEvent {
  final int version;
  final Map<String, dynamic> state;
  final Map<String, dynamic> ui;

  ContextUpdatedEvent({
    required this.version,
    required this.state,
    required this.ui,
  }) : super(
         eventType: 'context.updated',
         data: {'version': version, 'state': state, 'ui': ui},
       );

  factory ContextUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return ContextUpdatedEvent(
      version: json['version'] as int,
      state: json['state'] as Map<String, dynamic>,
      ui: json['ui'] as Map<String, dynamic>,
    );
  }
}

/// Événement : début d'utilisation d'un outil
class ToolStartEvent extends SSEEvent {
  final String tool;

  ToolStartEvent({required this.tool})
    : super(eventType: 'tool.start', data: {'tool': tool});

  factory ToolStartEvent.fromJson(Map<String, dynamic> json) {
    return ToolStartEvent(tool: json['tool'] as String);
  }
}

/// Événement : fin d'utilisation d'un outil
class ToolEndEvent extends SSEEvent {
  final String tool;

  ToolEndEvent({required this.tool})
    : super(eventType: 'tool.end', data: {'tool': tool});

  factory ToolEndEvent.fromJson(Map<String, dynamic> json) {
    return ToolEndEvent(tool: json['tool'] as String);
  }
}

/// Événement : erreur
class ErrorEvent extends SSEEvent {
  final String message;
  final String? code;

  ErrorEvent({required this.message, this.code})
    : super(
        eventType: 'error',
        data: {'message': message, if (code != null) 'code': code},
      );

  factory ErrorEvent.fromJson(Map<String, dynamic> json) {
    return ErrorEvent(
      message: json['message'] as String,
      code: json['code'] as String?,
    );
  }
}

/// Événement inconnu
class UnknownEvent extends SSEEvent {
  UnknownEvent({required super.eventType, required super.data});
}
