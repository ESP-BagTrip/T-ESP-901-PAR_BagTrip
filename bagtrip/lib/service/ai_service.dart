import 'dart:convert';

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class AiRepositoryImpl implements AiRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AiRepositoryImpl({ApiClient? apiClient, StorageService? storageService})
    : _apiClient = apiClient ?? ApiClient(),
      _storageService = storageService ?? StorageService();

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
      final response = await _apiClient.post(
        '/ai/inspire',
        data: {
          if (travelTypes != null) 'travelTypes': travelTypes,
          if (budgetRange != null) 'budgetRange': budgetRange,
          if (durationDays != null) 'durationDays': durationDays,
          if (companions != null) 'companions': companions,
          if (season != null) 'season': season,
          if (constraints != null) 'constraints': constraints,
        },
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['suggestions'] is List) {
          return Success(
            (data['suggestions'] as List)
                .map((s) => Map<String, dynamic>.from(s))
                .toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('get inspiration failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> acceptInspiration(
    Map<String, dynamic> suggestion, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/inspire/accept',
        data: {
          'suggestion': suggestion,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
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
    };

    debugPrint('[SSE] Connecting to $url');

    final sseStream = SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: url,
      header: {
        'Authorization': 'Bearer $token',
        'Accept': 'text/event-stream',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    await for (final event in sseStream) {
      if (event.data == null || event.data!.isEmpty) continue;

      final eventType = event.event ?? 'message';

      // Skip heartbeats
      if (eventType == 'heartbeat') continue;

      try {
        final data = json.decode(event.data!) as Map<String, dynamic>;
        yield {'event': eventType, 'data': data};
      } catch (e) {
        debugPrint('[SSE] Failed to parse event data: ${event.data}');
      }
    }

    debugPrint('[SSE] Stream closed');
  }
}
