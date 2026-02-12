import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  int? _currentContextVersion;
  String? _lastMessage;

  ChatBloc({
    SSEClient? sseClient,
    AgentService? agentService,
    MessageService? messageService,
    ApiClient? apiClient,
  }) : _sseClient = sseClient ?? SSEClient(),
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
    on<RefreshContext>(_onRefreshContext);
    // Internal events for SSE updates
    on<UpdateStreamingTextEvent>(_onUpdateStreamingText);
    on<MessageFinalReceivedEvent>(_onMessageFinalReceived);
    on<ContextUpdatedReceivedEvent>(_onContextUpdatedReceived);
    on<ToolStartReceivedEvent>(_onToolStartReceived);
    on<ToolEndReceivedEvent>(_onToolEndReceived);
    on<SSEErrorReceivedEvent>(_onSSEErrorReceived);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<ChatState> emit,
  ) async {
    debugPrint(
      '[ChatBloc] Loading history for conversation: ${event.conversationId}',
    );
    final currentState = state;
    // If already ChatLoaded, skip ChatLoading to avoid losing state.
    if (currentState is! ChatLoaded) {
      emit(const ChatLoading());
    }
    try {
      final messages = await _messageService.getMessagesByConversation(
        event.conversationId,
        limit: event.limit,
        offset: event.offset,
      );

      debugPrint('[ChatBloc] Loaded ${messages.length} messages');

      final chatMessages =
          messages
              .map(
                (m) => ChatMessage(
                  id: m.id,
                  role: m.role,
                  content: m.content,
                  createdAt: m.createdAt,
                  metadata: m.messageMetadata,
                ),
              )
              .toList();

      if (currentState is ChatLoaded) {
        emit(currentState.copyWith(messages: chatMessages, isStreaming: false));
      } else {
        emit(ChatLoaded(messages: chatMessages));
      }
    } catch (e) {
      debugPrint('[ChatBloc] Error loading history: $e');
      emit(ChatError('Failed to load history: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ChatLoaded) {
      emit(const ChatError('Chat not initialized'));
      return;
    }

    final userMessage = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: event.message,
      createdAt: DateTime.now(),
    );

    emit(
      currentState.copyWith(
        messages: [...currentState.messages, userMessage],
        isStreaming: true,
        streamingText: '',
      ),
    );

    _currentTripId = event.tripId;
    _currentConversationId = event.conversationId;
    _currentContextVersion = event.contextVersion;
    _lastMessage = event.message;

    _startSSEStream(
      tripId: event.tripId,
      conversationId: event.conversationId,
      message: event.message,
      contextVersion: event.contextVersion,
      emit: emit,
    );
  }

  void _startSSEStream({
    required String tripId,
    required String conversationId,
    required String message,
    required int? contextVersion,
    required Emitter<ChatState> emit,
  }) {
    debugPrint('[ChatBloc] _startSSEStream called');
    debugPrint('[ChatBloc] tripId: $tripId, conversationId: $conversationId');
    debugPrint('[ChatBloc] message: $message, contextVersion: $contextVersion');

    _sseSubscription?.cancel();

    final baseUrl = _apiClient.baseUrl;
    debugPrint('[ChatBloc] baseUrl: $baseUrl');
    // baseUrl already includes /v1, so use /agent/chat only.
    final endpoint = '/agent/chat';
    final fullUrl = '$baseUrl$endpoint';
    debugPrint('[ChatBloc] Full URL: $fullUrl');

    final body = {
      'trip_id': tripId,
      'conversation_id': conversationId,
      'message': message,
      if (contextVersion != null) 'context_version': contextVersion,
    };

    debugPrint('[ChatBloc] Starting SSE stream to: $baseUrl$endpoint');
    debugPrint('[ChatBloc] Body: $body');

    _sseSubscription = _sseClient
        .connectWithAuth(baseUrl: baseUrl, endpoint: endpoint, body: body)
        .listen(
          (sseEvent) {
            debugPrint('[ChatBloc] Received SSE event: ${sseEvent.eventType}');
            // Don't check emit.isDone - use add() to emit new states instead
            final currentState = state;
            if (currentState is! ChatLoaded) {
              debugPrint(
                '[ChatBloc] State is not ChatLoaded: ${currentState.runtimeType}',
              );
              return;
            }

            if (sseEvent is MessageDeltaEvent) {
              final currentText = currentState.streamingText ?? '';
              add(UpdateStreamingTextEvent(currentText + sseEvent.text));
            } else if (sseEvent is MessageFinalEvent) {
              add(
                MessageFinalReceivedEvent(
                  messageId: sseEvent.messageId,
                  text: sseEvent.text,
                ),
              );
            } else if (sseEvent is ContextUpdatedEvent) {
              final context = ChatContext.fromJson({
                'version': sseEvent.version,
                'state': sseEvent.state,
                'ui': sseEvent.ui,
              });

              _currentContextVersion = sseEvent.version;
              add(ContextUpdatedReceivedEvent(context: context));
            } else if (sseEvent is ToolStartEvent) {
              add(ToolStartReceivedEvent(tool: sseEvent.tool));
            } else if (sseEvent is ToolEndEvent) {
              add(const ToolEndReceivedEvent());
            } else if (sseEvent is ErrorEvent) {
              bool shouldRefresh =
                  sseEvent.message.contains('stale_context') ||
                  sseEvent.message.contains('Context version mismatch');
              add(
                SSEErrorReceivedEvent(
                  message: sseEvent.message,
                  shouldRefresh: shouldRefresh,
                ),
              );
            } else {
              debugPrint('Unknown SSE event type: ${sseEvent.eventType}');
            }
          },
          onError: (error, stackTrace) {
            debugPrint('[ChatBloc] Stream error: $error');
            debugPrint('[ChatBloc] Stack trace: $stackTrace');

            if (error is DioException) {
              String message = error.error?.toString() ?? 'Connection error';
              bool shouldRefresh = false;

              if (error.response?.statusCode == 409) {
                message = 'Context was updated. Please refresh.';
                shouldRefresh = true;
              } else if (error.response?.statusCode == 429) {
                message = 'Too many requests. Please wait a moment.';
              }

              add(
                SSEErrorReceivedEvent(
                  message: message,
                  shouldRefresh: shouldRefresh,
                ),
              );
            } else {
              add(
                SSEErrorReceivedEvent(
                  message: 'Stream error: $error',
                  shouldRefresh: false,
                ),
              );
            }
          },
          onDone: () {
            debugPrint('[ChatBloc] Stream done');
            final currentState = state;
            if (currentState is ChatLoaded) {
              debugPrint(
                '[ChatBloc] Current state - isStreaming: ${currentState.isStreaming}, hasStreamingText: ${currentState.streamingText != null}, error: ${currentState.error}',
              );
              // If stream ended without MessageFinalEvent, reload messages to get server-saved response.
              if (currentState.isStreaming ||
                  currentState.streamingText != null) {
                debugPrint(
                  '[ChatBloc] Stream ended while streaming or with partial text, will reload messages in 500ms',
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (!isClosed && _currentConversationId != null) {
                    debugPrint('[ChatBloc] Reloading messages...');
                    add(LoadHistory(conversationId: _currentConversationId!));
                  } else {
                    debugPrint(
                      '[ChatBloc] Cannot reload: isClosed=$isClosed, conversationId=$_currentConversationId',
                    );
                  }
                });
              } else {
                debugPrint('[ChatBloc] Stream ended normally');
                add(const ToolEndReceivedEvent());
              }
            } else {
              debugPrint(
                '[ChatBloc] State is not ChatLoaded: ${currentState.runtimeType}',
              );
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

  Future<void> _onBookOffer(BookOffer event, Emitter<ChatState> emit) async {
    try {
      final response = await _agentService.action(
        tripId: event.tripId,
        conversationId: event.conversationId,
        action: {'type': 'BOOK_${event.offerType}', 'offer_id': event.offerId},
        contextVersion: event.contextVersion,
      );

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

    add(
      SendMessage(
        tripId: _currentTripId ?? '',
        conversationId: _currentConversationId ?? '',
        message: event.quickReply,
        contextVersion: currentState.context?.version,
      ),
    );
  }

  void _onResetChat(ResetChat event, Emitter<ChatState> emit) {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _currentTripId = null;
    _currentConversationId = null;
    _currentContextVersion = null;
    _lastMessage = null;
    emit(const ChatInitial());
  }

  void _onReconnectStream(ReconnectStream event, Emitter<ChatState> emit) {
    if (_currentTripId != null &&
        _currentConversationId != null &&
        _lastMessage != null) {
      add(
        SendMessage(
          tripId: _currentTripId!,
          conversationId: _currentConversationId!,
          message: _lastMessage!,
          contextVersion: _currentContextVersion,
        ),
      );
    } else {
      _onResetChat(const ResetChat(), emit);
    }
  }

  Future<void> _onRefreshContext(
    RefreshContext event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());
    try {
      final messages = await _messageService.getMessagesByConversation(
        event.conversationId,
      );

      final chatMessages =
          messages
              .map(
                (m) => ChatMessage(
                  id: m.id,
                  role: m.role,
                  content: m.content,
                  createdAt: m.createdAt,
                  metadata: m.messageMetadata,
                ),
              )
              .toList();

      _currentContextVersion = null;

      emit(ChatLoaded(messages: chatMessages));
    } catch (e) {
      emit(ChatError('Failed to refresh context: $e'));
    }
  }

  // Handlers for internal SSE events
  void _onUpdateStreamingText(
    UpdateStreamingTextEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(streamingText: event.text));
    }
  }

  void _onMessageFinalReceived(
    MessageFinalReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final messages = currentState.messages.toList();
      if (messages.isNotEmpty &&
          messages.last.id.startsWith('temp-') &&
          messages.last.role == 'assistant') {
        messages.removeLast();
      }

      final assistantMessage = ChatMessage(
        id: event.messageId,
        role: 'assistant',
        content: event.text,
        createdAt: DateTime.now(),
      );

      emit(
        currentState.copyWith(
          messages: [...messages, assistantMessage],
          isStreaming: false,
        ),
      );
    }
  }

  void _onContextUpdatedReceived(
    ContextUpdatedReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(context: event.context));
    }
  }

  void _onToolStartReceived(
    ToolStartReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(activeTool: event.tool));
    }
  }

  void _onToolEndReceived(ToolEndReceivedEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(activeTool: null));
    }
  }

  void _onSSEErrorReceived(
    SSEErrorReceivedEvent event,
    Emitter<ChatState> emit,
  ) {
    debugPrint('[ChatBloc] Handling SSE error: ${event.message}');
    final currentState = state;
    if (currentState is ChatLoaded) {
      String errorMessage = event.message;
      if (errorMessage.contains('RESOURCE_EXHAUSTED') ||
          errorMessage.contains('429') ||
          errorMessage.contains('quota')) {
        errorMessage = 'API quota exceeded. Please try again later.';
      } else if (errorMessage.length > 200) {
        errorMessage = '${errorMessage.substring(0, 200)}...';
      }

      debugPrint('[ChatBloc] Emitting error state with message: $errorMessage');
      emit(currentState.copyWith(error: errorMessage, isStreaming: false));

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!isClosed && _currentConversationId != null) {
          debugPrint('[ChatBloc] Reloading messages after error...');
          add(LoadHistory(conversationId: _currentConversationId!));
        }
      });
    } else {
      debugPrint('[ChatBloc] Not in ChatLoaded state, emitting ChatError');
      emit(ChatError(event.message, shouldRefreshContext: event.shouldRefresh));
    }
  }

  @override
  Future<void> close() {
    _sseSubscription?.cancel();
    _sseClient.close();
    return super.close();
  }
}
