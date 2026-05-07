// Covers the non-SSE portion of AiRepositoryImpl. planTripStream / getInspiration
// go through a standalone Dio and are exercised by integration tests instead.

import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/ai_service.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockStorageService extends Mock implements StorageService {}

Response _response({
  required String path,
  required int statusCode,
  Object? data,
}) => Response(
  requestOptions: RequestOptions(path: path),
  statusCode: statusCode,
  data: data,
);

void main() {
  late _MockApiClient mockApiClient;
  late _MockStorageService mockStorageService;
  late AiRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    mockStorageService = _MockStorageService();
    repository = AiRepositoryImpl(
      apiClient: mockApiClient,
      storageService: mockStorageService,
    );
  });

  group('AiRepositoryImpl.getPostTripSuggestion', () {
    test('unwraps nested {suggestion: {...}} envelope', () async {
      when(() => mockApiClient.post('/ai/post-trip-suggestion')).thenAnswer(
        (_) async => _response(
          path: '/ai/post-trip-suggestion',
          statusCode: 200,
          data: <String, dynamic>{
            'suggestion': {'destination': 'Porto', 'reason': 'Similar vibes'},
          },
        ),
      );

      final result = await repository.getPostTripSuggestion();
      expect(result, isA<Success>());
      expect((result as Success).data['destination'], 'Porto');
    });

    test('passes through raw map if no suggestion envelope', () async {
      when(() => mockApiClient.post('/ai/post-trip-suggestion')).thenAnswer(
        (_) async => _response(
          path: '/ai/post-trip-suggestion',
          statusCode: 200,
          data: <String, dynamic>{'destination': 'Porto'},
        ),
      );

      final result = await repository.getPostTripSuggestion();
      expect((result as Success).data['destination'], 'Porto');
    });

    test('returns Failure on non-200', () async {
      when(() => mockApiClient.post('/ai/post-trip-suggestion')).thenAnswer(
        (_) async => _response(
          path: '/ai/post-trip-suggestion',
          statusCode: 402,
          data: <String, dynamic>{},
        ),
      );
      expect(await repository.getPostTripSuggestion(), isA<Failure>());
    });

    test('maps DioException to Failure', () async {
      when(() => mockApiClient.post('/ai/post-trip-suggestion')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ai/post-trip-suggestion'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repository.getPostTripSuggestion(), isA<Failure>());
    });
  });
}
