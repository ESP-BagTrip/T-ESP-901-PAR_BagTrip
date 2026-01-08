import 'package:bagtrip/chat/bloc/chat_bloc.dart';
import 'package:bagtrip/chat/bloc/chat_event.dart';
import 'package:bagtrip/chat/bloc/chat_state.dart';
import 'package:bagtrip/chat/widgets/widget_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatPage extends StatefulWidget {
  final String tripId;
  final String conversationId;

  const ChatPage({
    super.key,
    required this.tripId,
    required this.conversationId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger l'historique au démarrage après que le widget soit monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatBloc>().add(
          LoadHistory(conversationId: widget.conversationId),
        );
      }
    });
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
            return SafeArea(
              child: Column(
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
                          final widgetData = state.context!.ui.widgets[index];
                          return WidgetRenderer(
                            widgetData: widgetData,
                            onAction: (actionType, offerId) {
                              _handleWidgetAction(actionType, offerId, state);
                            },
                          );
                        },
                      ),
                    ),

                  // Zone de messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.messages.length +
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
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
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

  void _handleWidgetAction(
    String actionType,
    String? offerId,
    ChatLoaded state,
  ) {
    if (offerId == null) return;

    final offerType = actionType.contains('FLIGHT') ? 'FLIGHT' : 'HOTEL';

    if (actionType == 'SELECT_FLIGHT' || actionType == 'SELECT_HOTEL') {
      context.read<ChatBloc>().add(
        SelectOffer(
          tripId: widget.tripId,
          conversationId: widget.conversationId,
          offerId: offerId,
          offerType: offerType,
          contextVersion: state.context?.version,
        ),
      );
    } else if (actionType == 'BOOK_FLIGHT' || actionType == 'BOOK_HOTEL') {
      context.read<ChatBloc>().add(
        BookOffer(
          tripId: widget.tripId,
          conversationId: widget.conversationId,
          offerId: offerId,
          offerType: offerType,
          contextVersion: state.context?.version,
        ),
      );
    }
  }
}
