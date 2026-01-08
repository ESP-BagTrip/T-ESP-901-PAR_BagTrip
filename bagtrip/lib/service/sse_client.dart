import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      debugPrint('[SSE] Connecting to: $url');
      debugPrint('[SSE] Body: ${jsonEncode(body)}');

      // Créer la requête POST
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.body = jsonEncode(body);

      debugPrint('[SSE] Sending request...');
      // Envoyer la requête
      final streamedResponse =
          await _client?.send(request) ?? await http.Client().send(request);

      debugPrint('[SSE] Response status: ${streamedResponse.statusCode}');
      debugPrint('[SSE] Response headers: ${streamedResponse.headers}');

      if (streamedResponse.statusCode != 200) {
        debugPrint(
          '[SSE] Connection failed with status: ${streamedResponse.statusCode}',
        );
        yield ErrorEvent(
          message: 'SSE connection failed: ${streamedResponse.statusCode}',
          code: 'CONNECTION_ERROR',
        );
        return;
      }

      debugPrint('[SSE] Connection successful, starting to read stream...');

      // Parser le stream SSE
      String buffer = '';
      String? currentEventType;
      int lineCount = 0;

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        lineCount++;
        if (lineCount % 10 == 0) {
          debugPrint('[SSE] Received $lineCount lines');
        }

        if (chunk.isEmpty) {
          // Ligne vide = fin d'événement
          if (currentEventType != null && buffer.isNotEmpty) {
            debugPrint(
              '[SSE] Parsing event: $currentEventType with data: ${buffer.substring(0, buffer.length > 100 ? 100 : buffer.length)}...',
            );
            try {
              final event = SSEEvent.fromSSE(currentEventType, buffer.trim());
              debugPrint('[SSE] Event parsed successfully: ${event.eventType}');
              yield event;
            } catch (e, stackTrace) {
              debugPrint('[SSE] Failed to parse SSE event: $e');
              debugPrint('[SSE] Stack trace: $stackTrace');
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
          debugPrint('[SSE] Event type: $currentEventType');
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
        } else {
          debugPrint(
            '[SSE] Unknown chunk format: ${chunk.substring(0, chunk.length > 50 ? 50 : chunk.length)}',
          );
        }
      }

      debugPrint('[SSE] Stream ended. Total lines: $lineCount');

      // Si on a encore un événement en buffer à la fin du stream, l'émettre
      if (currentEventType != null && buffer.isNotEmpty) {
        try {
          final event = SSEEvent.fromSSE(currentEventType, buffer.trim());
          yield event;
        } catch (e) {
          yield ErrorEvent(
            message: 'Failed to parse final SSE event: $e',
            code: 'PARSE_ERROR',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[SSE] Exception caught: $e');
      debugPrint('[SSE] Stack trace: $stackTrace');
      yield ErrorEvent(message: 'SSE error: $e', code: 'STREAM_ERROR');
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
      yield ErrorEvent(message: 'No authentication token', code: 'AUTH_ERROR');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    yield* connect(url: '$baseUrl$endpoint', headers: headers, body: body);
  }

  /// Fermer la connexion
  void close() {
    _subscription?.cancel();
    _client?.close();
    _client = null;
  }

  void dispose() {
    close();
  }
}
