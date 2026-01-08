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
  List<Object?> get props => [
    tripId,
    conversationId,
    offerId,
    offerType,
    contextVersion,
  ];
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
  List<Object?> get props => [
    tripId,
    conversationId,
    offerId,
    offerType,
    contextVersion,
  ];
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

/// Rafraîchir le contexte
class RefreshContext extends ChatEvent {
  final String tripId;
  final String conversationId;

  const RefreshContext({required this.tripId, required this.conversationId});

  @override
  List<Object?> get props => [tripId, conversationId];
}

// Internal events for SSE stream updates (public but should only be used internally)
class UpdateStreamingTextEvent extends ChatEvent {
  final String text;

  const UpdateStreamingTextEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class MessageFinalReceivedEvent extends ChatEvent {
  final String messageId;
  final String text;

  const MessageFinalReceivedEvent({
    required this.messageId,
    required this.text,
  });

  @override
  List<Object?> get props => [messageId, text];
}

class ContextUpdatedReceivedEvent extends ChatEvent {
  final dynamic context; // ChatContext

  const ContextUpdatedReceivedEvent({required this.context});

  @override
  List<Object?> get props => [context];
}

class ToolStartReceivedEvent extends ChatEvent {
  final String tool;

  const ToolStartReceivedEvent({required this.tool});

  @override
  List<Object?> get props => [tool];
}

class ToolEndReceivedEvent extends ChatEvent {
  const ToolEndReceivedEvent();
}

class SSEErrorReceivedEvent extends ChatEvent {
  final String message;
  final bool shouldRefresh;

  const SSEErrorReceivedEvent({
    required this.message,
    required this.shouldRefresh,
  });

  @override
  List<Object?> get props => [message, shouldRefresh];
}
