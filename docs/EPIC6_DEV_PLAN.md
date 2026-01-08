# Epic 6: Client Chat Interface - Plan de Développement Complet

## 📋 Vue d'ensemble

**Objectif** : Créer l'interface de chat avec support SSE (Server-Sent Events), gestion des messages, et intégration avec le contexte backend pour permettre à l'utilisateur d'interagir avec l'agent IA de planification de voyage.

**Durée estimée** : 4-5 jours de développement

**Dépendances** : 
- Epic 4 (services AgentService, ApiClient doivent être fonctionnels)
- Epic 5 (ChatPage stub doit exister, tripId et conversationId disponibles)

**Livrables** :
- 1 client SSE pour Flutter
- 1 BLoC complet pour gérer le chat (events, states)
- 1 écran de chat fonctionnel avec streaming
- Modèles pour événements SSE et contexte
- Intégration avec l'API agent

**Statut** : ✅ **IMPLÉMENTÉ** (2026-01-08)

---

## 🎯 Objectifs détaillés

1. **Client SSE** : Créer un client SSE robuste pour recevoir les événements en streaming
2. **Modèles SSE** : Créer les modèles pour tous les types d'événements SSE
3. **Chat BLoC** : Créer un BLoC complet pour gérer l'état du chat, les messages, et le contexte
4. **Écran Chat** : Créer une interface de chat moderne avec zone de messages, widgets, et input
5. **Gestion du contexte** : Intégrer la gestion du contexte backend (versioning, widgets, quick replies)
6. **Actions rapides** : Permettre les actions sur les widgets (SELECT/BOOK)
7. **Historique** : Charger et afficher l'historique des messages

---

## 📦 Structure des tâches

### Tâche 6.1 : Créer les modèles d'événements SSE
**Fichier** : `bagtrip/lib/chat/models/sse_event.dart`

**Spécifications** :

Créer les modèles pour tous les types d'événements SSE émis par l'API.

```dart
import 'dart:convert';

/// Événement de base pour tous les événements SSE
abstract class SSEEvent {
  final String eventType;
  final Map<String, dynamic> data;

  SSEEvent({
    required this.eventType,
    required this.data,
  });

  factory SSEEvent.fromSSE(String eventType, String data) {
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
  }
}

/// Événement : delta de texte en streaming
class MessageDeltaEvent extends SSEEvent {
  final String text;

  MessageDeltaEvent({required this.text})
      : super(
          eventType: 'message.delta',
          data: {'text': text},
        );

  factory MessageDeltaEvent.fromJson(Map<String, dynamic> json) {
    return MessageDeltaEvent(text: json['text'] as String);
  }
}

/// Événement : message final avec ID
class MessageFinalEvent extends SSEEvent {
  final String messageId;
  final String text;

  MessageFinalEvent({
    required this.messageId,
    required this.text,
  }) : super(
          eventType: 'message.final',
          data: {
            'message_id': messageId,
            'text': text,
          },
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
          data: {
            'version': version,
            'state': state,
            'ui': ui,
          },
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
      : super(
          eventType: 'tool.start',
          data: {'tool': tool},
        );

  factory ToolStartEvent.fromJson(Map<String, dynamic> json) {
    return ToolStartEvent(tool: json['tool'] as String);
  }
}

/// Événement : fin d'utilisation d'un outil
class ToolEndEvent extends SSEEvent {
  final String tool;

  ToolEndEvent({required this.tool})
      : super(
          eventType: 'tool.end',
          data: {'tool': tool},
        );

  factory ToolEndEvent.fromJson(Map<String, dynamic> json) {
    return ToolEndEvent(tool: json['tool'] as String);
  }
}

/// Événement : erreur
class ErrorEvent extends SSEEvent {
  final String message;
  final String? code;

  ErrorEvent({
    required this.message,
    this.code,
  }) : super(
          eventType: 'error',
          data: {
            'message': message,
            if (code != null) 'code': code,
          },
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
  UnknownEvent({
    required String eventType,
    required Map<String, dynamic> data,
  }) : super(eventType: eventType, data: data);
}
```

**Critères d'acceptation** :
- ✅ Tous les types d'événements SSE modélisés
- ✅ Factory method pour parser les événements SSE
- ✅ Support des événements inconnus
- ✅ Parsing JSON robuste avec gestion d'erreurs

**Estimation** : 2h

---

### Tâche 6.2 : Créer le modèle de contexte
**Fichier** : `bagtrip/lib/chat/models/context.dart`

**Spécifications** :

Créer le modèle pour représenter le contexte (state + UI) reçu du backend.

```dart
class ChatContext {
  final int version;
  final ContextState state;
  final ContextUI ui;

  ChatContext({
    required this.version,
    required this.state,
    required this.ui,
  });

  factory ChatContext.fromJson(Map<String, dynamic> json) {
    return ChatContext(
      version: json['version'] as int,
      state: ContextState.fromJson(json['state'] as Map<String, dynamic>),
      ui: ContextUI.fromJson(json['ui'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'state': state.toJson(),
      'ui': ui.toJson(),
    };
  }
}

class ContextState {
  final String stage; // "collecting_requirements" | "searching" | "proposing" | "booking" | "done"
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? selected;

  ContextState({
    required this.stage,
    this.requirements,
    this.selected,
  });

  factory ContextState.fromJson(Map<String, dynamic> json) {
    return ContextState(
      stage: json['stage'] as String,
      requirements: json['requirements'] as Map<String, dynamic>?,
      selected: json['selected'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      if (requirements != null) 'requirements': requirements,
      if (selected != null) 'selected': selected,
    };
  }
}

class ContextUI {
  final List<WidgetData> widgets;
  final List<String> quickReplies;

  ContextUI({
    required this.widgets,
    required this.quickReplies,
  });

  factory ContextUI.fromJson(Map<String, dynamic> json) {
    return ContextUI(
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((w) => WidgetData.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      quickReplies: (json['quick_replies'] as List<dynamic>?)
              ?.map((r) => r as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'widgets': widgets.map((w) => w.toJson()).toList(),
      'quick_replies': quickReplies,
    };
  }
}

class WidgetData {
  final String type; // "FLIGHT_OFFER_CARD" | "HOTEL_OFFER_CARD" | "ITINERARY_SUMMARY" | "WARNING"
  final String? offerId;
  final String? title;
  final String? subtitle;
  final Map<String, dynamic>? data;
  final List<WidgetAction> actions;

  WidgetData({
    required this.type,
    this.offerId,
    this.title,
    this.subtitle,
    this.data,
    required this.actions,
  });

  factory WidgetData.fromJson(Map<String, dynamic> json) {
    return WidgetData(
      type: json['type'] as String,
      offerId: json['offer_id'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => WidgetAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (offerId != null) 'offer_id': offerId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (data != null) 'data': data,
      'actions': actions.map((a) => a.toJson()).toList(),
    };
  }
}

class WidgetAction {
  final String type; // "SELECT_FLIGHT" | "BOOK_FLIGHT" | "SELECT_HOTEL" | "BOOK_HOTEL"
  final String label;

  WidgetAction({
    required this.type,
    required this.label,
  });

  factory WidgetAction.fromJson(Map<String, dynamic> json) {
    return WidgetAction(
      type: json['type'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'label': label,
    };
  }
}
```

**Critères d'acceptation** :
- ✅ Modèle ChatContext avec version, state, ui
- ✅ Modèle ContextState avec stage, requirements, selected
- ✅ Modèle ContextUI avec widgets et quickReplies
- ✅ Modèle WidgetData pour les widgets
- ✅ Modèle WidgetAction pour les actions
- ✅ Parsing JSON robuste avec valeurs optionnelles

**Estimation** : 1h30

---

### Tâche 6.3 : Créer le client SSE
**Fichier** : `bagtrip/lib/service/sse_client.dart`

**Spécifications** :

Créer un client SSE pour Flutter qui parse les événements SSE et émet des événements typés.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bagtrip/chat/models/sse_event.dart';
import 'package:bagtrip/service/storage_service.dart';

class SSEClient {
  final StorageService _storageService;
  http.Client? _client;
  StreamSubscription? _subscription;

  SSEClient({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Connecter au stream SSE
  Stream<SSEEvent> connect({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    try {
      // Créer la requête POST
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.body = jsonEncode(body);

      // Envoyer la requête
      final streamedResponse = await _client?.send(request) ??
          await http.Client().send(request);

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        yield ErrorEvent(
          message: 'SSE connection failed: ${streamedResponse.statusCode}',
          code: 'CONNECTION_ERROR',
        );
        return;
      }

      // Parser le stream SSE
      String buffer = '';
      String? currentEventType;

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.isEmpty) {
          // Ligne vide = fin d'événement
          if (currentEventType != null && buffer.isNotEmpty) {
            try {
              yield SSEEvent.fromSSE(currentEventType, buffer.trim());
            } catch (e) {
              yield ErrorEvent(
                message: 'Failed to parse SSE event: $e',
                code: 'PARSE_ERROR',
              );
            }
            buffer = '';
            currentEventType = null;
          }
          continue;
        }

        if (chunk.startsWith('event:')) {
          currentEventType = chunk.substring(6).trim();
        } else if (chunk.startsWith('data:')) {
          final data = chunk.substring(5).trim();
          if (buffer.isNotEmpty) {
            buffer += '\n$data';
          } else {
            buffer = data;
          }
        } else if (chunk.startsWith('id:')) {
          // ID optionnel, ignoré pour l'instant
        } else if (chunk.startsWith('retry:')) {
          // Retry optionnel, ignoré pour l'instant
        }
      }
    } catch (e) {
      yield ErrorEvent(
        message: 'SSE error: $e',
        code: 'STREAM_ERROR',
      );
    }
  }

  /// Connecter avec authentification automatique
  Stream<SSEEvent> connectWithAuth({
    required String baseUrl,
    required String endpoint,
    required Map<String, dynamic> body,
  }) async* {
    final token = await _storageService.getToken();
    if (token == null) {
      yield ErrorEvent(
        message: 'No authentication token',
        code: 'AUTH_ERROR',
      );
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    yield* connect(
      url: '$baseUrl$endpoint',
      headers: headers,
      body: body,
    );
  }

  /// Fermer la connexion
  void close() {
    _subscription?.cancel();
    _client?.close();
    _client = null;
  }

  @override
  void dispose() {
    close();
  }
}
```

**Critères d'acceptation** :
- ✅ Client SSE qui parse les événements SSE standard
- ✅ Support des événements multi-lignes
- ✅ Gestion d'erreurs robuste
- ✅ Support de l'authentification automatique
- ✅ Stream typé avec SSEEvent
- ✅ Fermeture propre de la connexion

**Estimation** : 3h

**Dépendances** :
- Ajouter `http: ^1.1.0` à `pubspec.yaml`

---

### Tâche 6.4 : Créer les événements du Chat BLoC
**Fichier** : `bagtrip/lib/chat/bloc/chat_event.dart`

**Spécifications** :

Créer les événements pour le Chat BLoC.

```dart
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Charger l'historique des messages
class LoadHistory extends ChatEvent {
  final String conversationId;
  final int limit;
  final int offset;

  const LoadHistory({
    required this.conversationId,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [conversationId, limit, offset];
}

/// Envoyer un message
class SendMessage extends ChatEvent {
  final String tripId;
  final String conversationId;
  final String message;
  final int? contextVersion;

  const SendMessage({
    required this.tripId,
    required this.conversationId,
    required this.message,
    this.contextVersion,
  });

  @override
  List<Object?> get props => [tripId, conversationId, message, contextVersion];
}

/// Sélectionner une offre (flight/hotel)
class SelectOffer extends ChatEvent {
  final String tripId;
  final String conversationId;
  final String offerId;
  final String offerType; // "FLIGHT" | "HOTEL"
  final int? contextVersion;

  const SelectOffer({
    required this.tripId,
    required this.conversationId,
    required this.offerId,
    required this.offerType,
    this.contextVersion,
  });

  @override
  List<Object?> get props =>
      [tripId, conversationId, offerId, offerType, contextVersion];
}

/// Réserver une offre
class BookOffer extends ChatEvent {
  final String tripId;
  final String conversationId;
  final String offerId;
  final String offerType; // "FLIGHT" | "HOTEL"
  final int? contextVersion;

  const BookOffer({
    required this.tripId,
    required this.conversationId,
    required this.offerId,
    required this.offerType,
    this.contextVersion,
  });

  @override
  List<Object?> get props =>
      [tripId, conversationId, offerId, offerType, contextVersion];
}

/// Utiliser une quick reply
class UseQuickReply extends ChatEvent {
  final String quickReply;

  const UseQuickReply(this.quickReply);

  @override
  List<Object?> get props => [quickReply];
}

/// Réinitialiser le chat
class ResetChat extends ChatEvent {
  const ResetChat();
}

/// Reconnecter au stream SSE
class ReconnectStream extends ChatEvent {
  const ReconnectStream();
}
```

**Critères d'acceptation** :
- ✅ Tous les événements nécessaires définis
- ✅ Utilisation de Equatable pour la comparaison
- ✅ Paramètres clairs et typés

**Estimation** : 30 minutes

**Dépendances** :
- Ajouter `equatable: ^2.0.5` à `pubspec.yaml`

---

### Tâche 6.5 : Créer les états du Chat BLoC
**Fichier** : `bagtrip/lib/chat/bloc/chat_state.dart`

**Spécifications** :

Créer les états pour le Chat BLoC.

```dart
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
    String? streamingText,
    String? activeTool,
    String? error,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      context: context ?? this.context,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      activeTool: activeTool ?? this.activeTool,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [messages, context, isStreaming, streamingText, activeTool, error];
}

/// Erreur
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
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
```

**Critères d'acceptation** :
- ✅ Tous les états nécessaires définis
- ✅ ChatLoaded avec copyWith pour les mises à jour immutables
- ✅ Modèle ChatMessage pour représenter les messages
- ✅ Utilisation de Equatable

**Estimation** : 1h

---

### Tâche 6.6 : Créer le Chat BLoC
**Fichier** : `bagtrip/lib/chat/bloc/chat_bloc.dart`

**Spécifications** :

Créer le BLoC principal pour gérer le chat, le streaming SSE, et le contexte.

```dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/chat/bloc/chat_event.dart';
import 'package:bagtrip/chat/bloc/chat_state.dart';
import 'package:bagtrip/chat/models/sse_event.dart';
import 'package:bagtrip/chat/models/context.dart';
import 'package:bagtrip/service/sse_client.dart';
import 'package:bagtrip/service/agent_service.dart';
import 'package:bagtrip/service/message_service.dart';
import 'package:bagtrip/service/api_client.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SSEClient _sseClient;
  final AgentService _agentService;
  final MessageService _messageService;
  final ApiClient _apiClient;
  StreamSubscription<SSEEvent>? _sseSubscription;
  String? _currentTripId;
  String? _currentConversationId;
  String? _currentContextVersion;

  ChatBloc({
    SSEClient? sseClient,
    AgentService? agentService,
    MessageService? messageService,
    ApiClient? apiClient,
  })  : _sseClient = sseClient ?? SSEClient(),
        _agentService = agentService ?? AgentService(),
        _messageService = messageService ?? MessageService(),
        _apiClient = apiClient ?? ApiClient(),
        super(const ChatInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage);
    on<SelectOffer>(_onSelectOffer);
    on<BookOffer>(_onBookOffer);
    on<UseQuickReply>(_onUseQuickReply);
    on<ResetChat>(_onResetChat);
    on<ReconnectStream>(_onReconnectStream);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    try {
      final messages = await _messageService.getMessagesByConversation(
        event.conversationId,
        limit: event.limit,
        offset: event.offset,
      );

      final chatMessages = messages
          .map((m) => ChatMessage(
                id: m.id,
                role: m.role,
                content: m.content,
                createdAt: m.createdAt,
                metadata: m.messageMetadata,
              ))
          .toList();

      emit(ChatLoaded(messages: chatMessages));
    } catch (e) {
      emit(ChatError('Failed to load history: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) {
      emit(ChatError('Chat not initialized'));
      return;
    }

    // Ajouter le message utilisateur à la liste
    final userMessage = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: event.message,
      createdAt: DateTime.now(),
    );

    emit(currentState.copyWith(
      messages: [...currentState.messages, userMessage],
      isStreaming: true,
      streamingText: '',
      error: null,
    ));

    // Sauvegarder le message utilisateur (optionnel, peut être fait côté serveur)
    try {
      await _messageService.createMessage(
        event.conversationId,
        role: 'user',
        content: event.message,
      );
    } catch (e) {
      // Log l'erreur mais continue le streaming
      print('Failed to save user message: $e');
    }

    // Démarrer le stream SSE
    _currentTripId = event.tripId;
    _currentConversationId = event.conversationId;
    _currentContextVersion = event.contextVersion?.toString();

    await _startSSEStream(
      tripId: event.tripId,
      conversationId: event.conversationId,
      message: event.message,
      contextVersion: event.contextVersion,
      emit: emit,
    );
  }

  Future<void> _startSSEStream({
    required String tripId,
    required String conversationId,
    required String message,
    required int? contextVersion,
    required Emitter<ChatState> emit,
  }) async {
    // Fermer la connexion précédente si elle existe
    _sseSubscription?.cancel();

    final baseUrl = _apiClient.baseUrl;
    final endpoint = '/v1/agent/chat';

    final body = {
      'trip_id': tripId,
      'conversation_id': conversationId,
      'message': message,
      if (contextVersion != null) 'context_version': contextVersion,
    };

    _sseSubscription = _sseClient
        .connectWithAuth(
          baseUrl: baseUrl,
          endpoint: endpoint,
          body: body,
        )
        .listen(
      (sseEvent) {
        final currentState = state;
        if (currentState is! ChatLoaded) return;

        if (sseEvent is MessageDeltaEvent) {
          // Accumuler le texte en streaming
          final currentText = currentState.streamingText ?? '';
          emit(currentState.copyWith(
            streamingText: currentText + sseEvent.text,
            isStreaming: true,
          ));
        } else if (sseEvent is MessageFinalEvent) {
          // Remplacer le message temporaire par le message final
          final messages = currentState.messages.toList();
          if (messages.isNotEmpty &&
              messages.last.id.startsWith('temp-') &&
              messages.last.role == 'assistant') {
            messages.removeLast();
          }

          final assistantMessage = ChatMessage(
            id: sseEvent.messageId,
            role: 'assistant',
            content: sseEvent.text,
            createdAt: DateTime.now(),
          );

          emit(currentState.copyWith(
            messages: [...messages, assistantMessage],
            isStreaming: false,
            streamingText: null,
          ));
        } else if (sseEvent is ContextUpdatedEvent) {
          // Mettre à jour le contexte
          final context = ChatContext.fromJson({
            'version': sseEvent.version,
            'state': sseEvent.state,
            'ui': sseEvent.ui,
          });

          _currentContextVersion = sseEvent.version.toString();

          emit(currentState.copyWith(
            context: context,
            isStreaming: currentState.isStreaming,
          ));
        } else if (sseEvent is ToolStartEvent) {
          emit(currentState.copyWith(
            activeTool: sseEvent.tool,
            isStreaming: true,
          ));
        } else if (sseEvent is ToolEndEvent) {
          emit(currentState.copyWith(
            activeTool: null,
            isStreaming: currentState.isStreaming,
          ));
        } else if (sseEvent is ErrorEvent) {
          emit(currentState.copyWith(
            error: sseEvent.message,
            isStreaming: false,
            streamingText: null,
          ));
        }
      },
      onError: (error) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(
            error: 'Stream error: $error',
            isStreaming: false,
            streamingText: null,
          ));
        } else {
          emit(ChatError('Stream error: $error'));
        }
      },
      onDone: () {
        final currentState = state;
        if (currentState is ChatLoaded) {
          emit(currentState.copyWith(
            isStreaming: false,
            activeTool: null,
          ));
        }
      },
    );
  }

  Future<void> _onSelectOffer(
    SelectOffer event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _agentService.action(
        tripId: event.tripId,
        conversationId: event.conversationId,
        action: {
          'type': 'SELECT_${event.offerType}',
          'offer_id': event.offerId,
        },
        contextVersion: event.contextVersion,
      );

      // Recharger le contexte si nécessaire
      // (l'API peut retourner un nouveau contexte)
      if (response['context'] != null) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          final context = ChatContext.fromJson(response['context']);
          emit(currentState.copyWith(context: context));
        }
      }
    } catch (e) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(error: 'Failed to select offer: $e'));
      } else {
        emit(ChatError('Failed to select offer: $e'));
      }
    }
  }

  Future<void> _onBookOffer(
    BookOffer event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _agentService.action(
        tripId: event.tripId,
        conversationId: event.conversationId,
        action: {
          'type': 'BOOK_${event.offerType}',
          'offer_id': event.offerId,
        },
        contextVersion: event.contextVersion,
      );

      // Recharger le contexte si nécessaire
      if (response['context'] != null) {
        final currentState = state;
        if (currentState is ChatLoaded) {
          final context = ChatContext.fromJson(response['context']);
          emit(currentState.copyWith(context: context));
        }
      }
    } catch (e) {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(error: 'Failed to book offer: $e'));
      } else {
        emit(ChatError('Failed to book offer: $e'));
      }
    }
  }

  Future<void> _onUseQuickReply(
    UseQuickReply event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) return;

    // Envoyer le quick reply comme un message normal
    add(SendMessage(
      tripId: _currentTripId ?? '',
      conversationId: _currentConversationId ?? '',
      message: event.quickReply,
      contextVersion: currentState.context?.version,
    ));
  }

  void _onResetChat(ResetChat event, Emitter<ChatState> emit) {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _currentTripId = null;
    _currentConversationId = null;
    _currentContextVersion = null;
    emit(const ChatInitial());
  }

  void _onReconnectStream(
    ReconnectStream event,
    Emitter<ChatState> emit,
  ) {
    // Réessayer la dernière requête si possible
    // (nécessite de stocker le dernier message)
    // Pour l'instant, juste réinitialiser
    _onResetChat(const ResetChat(), emit);
  }

  @override
  Future<void> close() {
    _sseSubscription?.cancel();
    _sseClient.close();
    return super.close();
  }
}
```

**Note** : Il faudra créer `MessageService` si ce n'est pas déjà fait, ou utiliser directement `ApiClient`.

**Critères d'acceptation** :
- ✅ Gestion complète du streaming SSE
- ✅ Mise à jour des messages en temps réel
- ✅ Gestion du contexte backend
- ✅ Gestion des actions (SELECT/BOOK)
- ✅ Gestion des quick replies
- ✅ Gestion d'erreurs robuste
- ✅ Fermeture propre des ressources

**Estimation** : 5h

---

### Tâche 6.7 : Créer le service MessageService (si nécessaire)
**Fichier** : `bagtrip/lib/service/message_service.dart`

**Spécifications** :

Créer un service pour gérer les messages (récupération de l'historique, création).

```dart
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/chat/bloc/chat_state.dart';

class MessageService {
  final ApiClient _apiClient;

  MessageService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Récupérer les messages d'une conversation
  Future<List<MessageModel>> getMessagesByConversation(
    String conversationId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/conversations/$conversationId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
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

  /// Créer un message
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

/// Modèle de message pour le service
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
      conversationId: json['conversationId'] as String? ??
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
```

**Critères d'acceptation** :
- ✅ Méthode getMessagesByConversation avec pagination
- ✅ Méthode createMessage
- ✅ Gestion d'erreurs appropriée
- ✅ Parsing JSON robuste

**Estimation** : 1h

---

### Tâche 6.8 : Créer l'écran ChatPage
**Fichier** : `bagtrip/lib/pages/chat_page.dart`

**Spécifications** :

Créer l'écran de chat complet avec zone de messages, widgets, input, et quick replies.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bagtrip/chat/bloc/chat_bloc.dart';
import 'package:bagtrip/chat/bloc/chat_event.dart';
import 'package:bagtrip/chat/bloc/chat_state.dart';

class ChatPage extends StatefulWidget {
  final String tripId;
  final String conversationId;

  const ChatPage({
    Key? key,
    required this.tripId,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger l'historique au démarrage
    context.read<ChatBloc>().add(
          LoadHistory(conversationId: widget.conversationId),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final state = context.read<ChatBloc>().state;
    final contextVersion = state is ChatLoaded ? state.context?.version : null;

    context.read<ChatBloc>().add(
          SendMessage(
            tripId: widget.tripId,
            conversationId: widget.conversationId,
            message: text,
            contextVersion: contextVersion,
          ),
        );

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planification IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatBloc>().add(
                    LoadHistory(conversationId: widget.conversationId),
                  );
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded) {
            // Auto-scroll quand de nouveaux messages arrivent
            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
          }
        },
        builder: (context, state) {
          if (state is ChatInitial || state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.red[800]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChatBloc>().add(
                            LoadHistory(conversationId: widget.conversationId),
                          );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ChatLoaded) {
            return Column(
              children: [
                // Zone de widgets (cartes)
                if (state.context?.ui.widgets.isNotEmpty ?? false)
                  Container(
                    height: 200,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.context!.ui.widgets.length,
                      itemBuilder: (context, index) {
                        final widget = state.context!.ui.widgets[index];
                        return _buildWidgetCard(widget, state);
                      },
                    ),
                  ),

                // Zone de messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length +
                        (state.isStreaming && state.streamingText != null
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index < state.messages.length) {
                        return _buildMessageBubble(state.messages[index]);
                      } else {
                        // Message en streaming
                        return _buildStreamingMessage(state.streamingText!);
                      }
                    },
                  ),
                ),

                // Quick replies
                if (state.context?.ui.quickReplies.isNotEmpty ?? false)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.context!.ui.quickReplies.length,
                      itemBuilder: (context, index) {
                        final reply = state.context!.ui.quickReplies[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(reply),
                            onDeleted: () {
                              context.read<ChatBloc>().add(
                                    UseQuickReply(reply),
                                  );
                            },
                            deleteIcon: const Icon(Icons.send, size: 16),
                          ),
                        );
                      },
                    ),
                  ),

                // Indicateur de tool actif
                if (state.activeTool != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recherche en cours...',
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ],
                    ),
                  ),

                // Erreur
                if (state.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.red[50],
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.error!,
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            context.read<ChatBloc>().add(
                                  LoadHistory(
                                    conversationId: widget.conversationId,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ),

                // Input message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Tapez votre message...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !state.isStreaming,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: state.isStreaming ? null : _sendMessage,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.smart_toy, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingMessage(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue[100],
            child: const Icon(Icons.smart_toy, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue[600]!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetCard(WidgetData widget, ChatLoaded state) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.title != null)
                Text(
                  widget.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const Spacer(),
              if (widget.actions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: widget.actions.map((action) {
                    return ElevatedButton(
                      onPressed: () {
                        if (widget.offerId != null) {
                          if (action.type == 'SELECT_FLIGHT' ||
                              action.type == 'SELECT_HOTEL') {
                            context.read<ChatBloc>().add(
                                  SelectOffer(
                                    tripId: widget.tripId,
                                    conversationId: widget.conversationId,
                                    offerId: widget.offerId!,
                                    offerType: action.type.contains('FLIGHT')
                                        ? 'FLIGHT'
                                        : 'HOTEL',
                                    contextVersion: state.context?.version,
                                  ),
                                );
                          } else if (action.type == 'BOOK_FLIGHT' ||
                              action.type == 'BOOK_HOTEL') {
                            context.read<ChatBloc>().add(
                                  BookOffer(
                                    tripId: widget.tripId,
                                    conversationId: widget.conversationId,
                                    offerId: widget.offerId!,
                                    offerType: action.type.contains('FLIGHT')
                                        ? 'FLIGHT'
                                        : 'HOTEL',
                                    contextVersion: state.context?.version,
                                  ),
                                );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(action.label),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Note** : Il faudra corriger les références à `widget.tripId` et `widget.conversationId` dans `_buildWidgetCard` - ces valeurs doivent être passées depuis le widget parent.

**Critères d'acceptation** :
- ✅ Zone de messages scrollable avec bulles de chat
- ✅ Affichage des messages en streaming
- ✅ Zone de widgets (cartes horizontales)
- ✅ Input message avec bouton send
- ✅ Quick replies cliquables
- ✅ Indicateur de tool actif
- ✅ Gestion d'erreurs avec affichage
- ✅ Auto-scroll vers le bas
- ✅ UI moderne et responsive
- ✅ Désactivation de l'input pendant le streaming

**Estimation** : 4h

---

### Tâche 6.9 : Intégrer le Chat BLoC dans l'application
**Fichier** : `bagtrip/lib/navigation/app_router.dart` (ou fichier d'injection de dépendances)

**Spécifications** :

S'assurer que le ChatBloc est fourni via BlocProvider dans l'application.

```dart
// Dans app_router.dart ou main.dart
BlocProvider(
  create: (context) => ChatBloc(),
  child: ChatPage(
    tripId: tripId,
    conversationId: conversationId,
  ),
)
```

**Critères d'acceptation** :
- ✅ ChatBloc fourni via BlocProvider
- ✅ Navigation vers ChatPage fonctionnelle
- ✅ Paramètres tripId et conversationId passés correctement

**Estimation** : 30 minutes

---

## 📁 Structure des fichiers à créer/modifier

### Nouveaux fichiers

```
bagtrip/lib/
├── chat/
│   ├── bloc/
│   │   ├── chat_bloc.dart                    [❌ À CRÉER]
│   │   ├── chat_event.dart                   [❌ À CRÉER]
│   │   └── chat_state.dart                   [❌ À CRÉER]
│   └── models/
│       ├── sse_event.dart                    [❌ À CRÉER]
│       └── context.dart                      [❌ À CRÉER]
├── service/
│   ├── sse_client.dart                       [❌ À CRÉER]
│   └── message_service.dart                  [❌ À CRÉER]
└── pages/
    └── chat_page.dart                        [⚠️ STUB EXISTANT - À COMPLÉTER]
```

### Fichiers à modifier

```
bagtrip/lib/
├── navigation/
│   └── app_router.dart                       [⚠️ À MODIFIER - ajouter BlocProvider]
└── pubspec.yaml                              [⚠️ À MODIFIER - ajouter dépendances]
```

---

## 🔄 Flux de fonctionnement

### Flow complet

```
1. User arrive sur ChatPage
   → ChatBloc charge l'historique (LoadHistory)
   → Affichage des messages existants

2. User tape un message et envoie
   → ChatBloc envoie SendMessage
   → Message utilisateur ajouté à la liste
   → Connexion SSE démarrée

3. SSE Stream
   → message.delta : texte accumulé en streaming
   → tool.start/end : indicateur de recherche
   → context.updated : widgets et quick replies mis à jour
   → message.final : message final avec ID

4. User clique sur une action (SELECT/BOOK)
   → ChatBloc envoie SelectOffer/BookOffer
   → AgentService.action() appelé
   → Contexte mis à jour si nécessaire

5. User clique sur quick reply
   → ChatBloc envoie UseQuickReply
   → Traité comme SendMessage
```

---

## 🔒 Validation et gestion d'erreurs

### Gestion des erreurs SSE

- **Erreurs de connexion** : Afficher message d'erreur, permettre reconnexion
- **Erreurs de parsing** : Logger et continuer le stream si possible
- **Timeouts** : Gérer les timeouts avec message clair
- **Context version mismatch** : Gérer l'erreur "stale context" et recharger

### Gestion des erreurs de l'API

- **Erreurs réseau** : Afficher message clair, permettre retry
- **Erreurs d'authentification** : Rediriger vers login
- **Erreurs de validation** : Afficher message d'erreur dans l'UI

### Validation

- **Message vide** : Ne pas envoyer
- **Context version** : Envoyer la version actuelle si disponible
- **Streaming** : Désactiver l'input pendant le streaming

---

## ✅ Checklist de validation

### Modèles
- [ ] SSEEvent et sous-classes créées
- [ ] ChatContext et sous-classes créées
- [ ] Parsing JSON robuste avec gestion d'erreurs
- [ ] Support des valeurs optionnelles

### Services
- [ ] SSEClient : connexion SSE fonctionnelle
- [ ] SSEClient : parsing des événements SSE
- [ ] SSEClient : gestion d'erreurs
- [ ] MessageService : récupération historique
- [ ] MessageService : création de messages

### BLoC
- [ ] ChatBloc : gestion du streaming SSE
- [ ] ChatBloc : mise à jour des messages
- [ ] ChatBloc : gestion du contexte
- [ ] ChatBloc : gestion des actions (SELECT/BOOK)
- [ ] ChatBloc : gestion des quick replies
- [ ] ChatBloc : fermeture propre des ressources

### UI
- [ ] ChatPage : affichage des messages
- [ ] ChatPage : streaming en temps réel
- [ ] ChatPage : zone de widgets
- [ ] ChatPage : input message
- [ ] ChatPage : quick replies
- [ ] ChatPage : indicateur de tool actif
- [ ] ChatPage : gestion d'erreurs
- [ ] ChatPage : auto-scroll
- [ ] ChatPage : UI moderne et responsive

### Intégration
- [ ] ChatBloc fourni via BlocProvider
- [ ] Navigation vers ChatPage fonctionnelle
- [ ] Paramètres tripId et conversationId passés
- [ ] Intégration avec AgentService
- [ ] Intégration avec MessageService

### Tests
- [ ] Test manuel : connexion SSE
- [ ] Test manuel : envoi de message
- [ ] Test manuel : réception streaming
- [ ] Test manuel : actions sur widgets
- [ ] Test manuel : quick replies
- [ ] Test manuel : gestion d'erreurs
- [ ] Test manuel : reconnexion après erreur

---

## 🚀 Ordre d'exécution recommandé

1. **Tâche 6.1** : Créer modèles SSEEvent (2h)
2. **Tâche 6.2** : Créer modèle ChatContext (1h30)
3. **Tâche 6.3** : Créer SSEClient (3h)
4. **Tâche 6.4** : Créer ChatEvent (30 min)
5. **Tâche 6.5** : Créer ChatState (1h)
6. **Tâche 6.7** : Créer MessageService (1h)
7. **Tâche 6.6** : Créer ChatBloc (5h)
8. **Tâche 6.8** : Créer ChatPage (4h)
9. **Tâche 6.9** : Intégrer dans l'application (30 min)

**Total estimé** : ~18h30 (4-5 jours)

---

## 📝 Notes importantes

### Dépendances requises

Ajouter à `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.1.0          # Pour SSE client
  equatable: ^2.0.5    # Pour comparaison d'états
  flutter_bloc: ^8.1.3 # Déjà présent normalement
```

### Pattern SSE

- **Format standard** : `event: <type>\ndata: <json>\n\n`
- **Multi-lignes** : Les données peuvent être sur plusieurs lignes
- **Parsing** : Parser ligne par ligne, accumuler les données

### Gestion du contexte

- **Versioning** : Toujours envoyer la version actuelle du contexte
- **Optimistic locking** : Le backend vérifie la version
- **Stale context** : Si erreur, recharger le contexte et réessayer

### Streaming

- **Message temporaire** : Créer un message temporaire pendant le streaming
- **Remplacer** : Remplacer par le message final avec ID
- **Accumulation** : Accumuler le texte delta par delta

### Widgets

- **Rendu basique** : Pour Epic 6, rendu simple des widgets (cartes basiques)
- **Epic 7** : Les widgets seront rendus de manière plus sophistiquée
- **Actions** : Les actions SELECT/BOOK sont fonctionnelles

### Performance

- **Scroll** : Utiliser ListView.builder pour de meilleures performances
- **Streaming** : Limiter les rebuilds en utilisant copyWith
- **Mémoire** : Limiter le nombre de messages chargés (pagination)

---

## 🔗 Liens avec les épics suivants

- **Epic 7** : Les widgets seront rendus de manière plus sophistiquée (FlightOfferCard, HotelOfferCard, etc.)
- **Epic 8** : Amélioration de la gestion d'erreurs, rate limiting, timeouts

---

## 📚 Références

- Services existants : `bagtrip/lib/service/agent_service.dart`, `api_client.dart` (Epic 4)
- Modèles existants : `bagtrip/lib/models/conversation.dart` (Epic 5)
- API endpoints : Voir Epic 3 pour les endpoints agent
- Format SSE : Voir Epic 3 pour le format des événements SSE
- Navigation : `bagtrip/lib/navigation/app_router.dart`

---

**Date de création** : 2026-01-08
**Dernière mise à jour** : 2026-01-08
**Statut** : ✅ **IMPLÉMENTÉ**

## ✅ Implémentation terminée

Toutes les tâches ont été complétées avec succès :

- ✅ **Tâche 6.1** : Modèles SSE créés (`bagtrip/lib/chat/models/sse_event.dart`)
- ✅ **Tâche 6.2** : Modèles de contexte créés (`bagtrip/lib/chat/models/context.dart`)
- ✅ **Tâche 6.3** : Client SSE implémenté (`bagtrip/lib/service/sse_client.dart`)
- ✅ **Tâche 6.4** : Événements Chat BLoC créés (`bagtrip/lib/chat/bloc/chat_event.dart`)
- ✅ **Tâche 6.5** : États Chat BLoC créés (`bagtrip/lib/chat/bloc/chat_state.dart`)
- ✅ **Tâche 6.6** : Chat BLoC implémenté (`bagtrip/lib/chat/bloc/chat_bloc.dart`)
- ✅ **Tâche 6.7** : MessageService créé (`bagtrip/lib/service/message_service.dart`)
- ✅ **Tâche 6.8** : ChatPage UI complétée (`bagtrip/lib/pages/chat_page.dart`)
- ✅ **Tâche 6.9** : Intégration dans le router (`bagtrip/lib/navigation/app_router.dart`)

### Fichiers créés

- `bagtrip/lib/chat/models/sse_event.dart` - Modèles d'événements SSE
- `bagtrip/lib/chat/models/context.dart` - Modèles de contexte
- `bagtrip/lib/service/sse_client.dart` - Client SSE
- `bagtrip/lib/service/message_service.dart` - Service de gestion des messages
- `bagtrip/lib/chat/bloc/chat_event.dart` - Événements BLoC
- `bagtrip/lib/chat/bloc/chat_state.dart` - États BLoC
- `bagtrip/lib/chat/bloc/chat_bloc.dart` - BLoC principal
- `bagtrip/lib/pages/chat_page.dart` - Interface de chat complète

### Fichiers modifiés

- `bagtrip/lib/navigation/app_router.dart` - Route `/chat` ajoutée avec BlocProvider
- `bagtrip/lib/pages/travelers_page.dart` - Navigation mise à jour pour utiliser le router

### Fonctionnalités implémentées

- ✅ Streaming SSE en temps réel avec accumulation de texte
- ✅ Gestion du contexte avec versioning
- ✅ Affichage des widgets avec actions SELECT/BOOK
- ✅ Quick replies intégrées
- ✅ Chargement de l'historique des messages
- ✅ Gestion d'erreurs et récupération
- ✅ Interface utilisateur moderne avec Material Design
- ✅ Auto-scroll vers les derniers messages
