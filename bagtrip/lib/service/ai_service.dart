import 'dart:async';
import 'dart:convert';

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AiRepositoryImpl implements AiRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AiRepositoryImpl({
    required ApiClient apiClient,
    required StorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  @override
  Future<Result<List<Map<String, dynamic>>>> getInspiration({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
    String? constraints,
  }) async {
    try {
      await for (final event in planTripStream(
        travelTypes: travelTypes,
        budgetRange: budgetRange,
        durationDays: durationDays,
        companions: companions,
        constraints: constraints,
        mode: 'destinations_only',
      )) {
        final type = event['event'] as String?;
        final data = event['data'] as Map<String, dynamic>? ?? {};

        // Return immediately when we receive destinations
        if (type == 'destinations' || type == 'complete') {
          final destinations = data['destinations'] as List? ?? [];
          return Success(destinations.cast<Map<String, dynamic>>());
        }

        // Stop waiting on terminal events
        if (type == 'done' || type == 'error') break;
      }
      return const Success([]);
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> acceptInspiration(
    Map<String, dynamic> suggestion, {
    String? startDate,
    String? endDate,
    String? dateMode,
    String? originCity,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/plan-trip/accept',
        data: {
          'suggestion': suggestion,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (dateMode != null) 'dateMode': dateMode,
          if (originCity != null) 'originCity': originCity,
        },
      );
      if (response.statusCode == 200) {
        return Success(Map<String, dynamic>.from(response.data));
      }
      return loggedFailure(
        UnknownError('accept inspiration failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getPostTripSuggestion() async {
    try {
      final response = await _apiClient.post('/ai/post-trip-suggestion');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestion'] != null) {
          return Success(Map<String, dynamic>.from(data['suggestion']));
        }
        return Success(Map<String, dynamic>.from(data));
      }
      return loggedFailure(
        UnknownError('get post-trip suggestion failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Stream<Map<String, dynamic>> planTripStream({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? constraints,
    String? departureDate,
    String? returnDate,
    String? originCity,
    String? destinationCity,
    String? destinationIata,
    String? mode,
  }) async* {
    final token = await _storageService.getToken();
    final url = '${_apiClient.baseUrl}/ai/plan-trip/stream';

    final body = <String, dynamic>{
      if (travelTypes != null) 'travelTypes': travelTypes,
      if (budgetRange != null) 'budgetRange': budgetRange,
      if (durationDays != null) 'durationDays': durationDays,
      if (companions != null) 'companions': companions,
      if (constraints != null) 'constraints': constraints,
      if (departureDate != null) 'departureDate': departureDate,
      if (returnDate != null) 'returnDate': returnDate,
      if (originCity != null) 'originCity': originCity,
      if (destinationCity != null) 'destinationCity': destinationCity,
      if (destinationIata != null) 'destinationIata': destinationIata,
      if (mode != null) 'mode': mode,
    };

    if (kDebugMode) debugPrint('[SSE] Connecting to $url');

    // Use Dio with ResponseType.stream for real streaming (flutter_client_sse
    // buffers the entire response on some platforms).
    final dio = Dio();
    final response = await dio.post<ResponseBody>(
      url,
      data: body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/event-stream',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.stream,
      ),
    );

    // Parse the SSE stream line by line
    String currentEvent = '';
    String currentData = '';

    final byteStream = response.data!.stream;
    final lines = byteStream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final chunk in lines) {
      if (chunk.isEmpty) {
        // Empty line = end of SSE event block
        if (currentData.isNotEmpty) {
          final eventType = currentEvent.isNotEmpty ? currentEvent : 'message';

          if (eventType != 'heartbeat') {
            try {
              final data = json.decode(currentData) as Map<String, dynamic>;
              if (kDebugMode) debugPrint('[SSE] Event: $eventType');
              yield {'event': eventType, 'data': data};
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[SSE] Failed to parse: $currentData');
              }
            }
          }
        }
        currentEvent = '';
        currentData = '';
        continue;
      }

      if (chunk.startsWith('event: ')) {
        currentEvent = chunk.substring(7);
      } else if (chunk.startsWith('data: ')) {
        currentData += chunk.substring(6);
      }
    }

    dio.close();
    if (kDebugMode) debugPrint('[SSE] Stream closed');
  }
}
