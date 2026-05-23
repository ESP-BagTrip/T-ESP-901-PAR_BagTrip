// ignore_for_file: avoid_redundant_argument_values

import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/auth_service.dart';
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
  late _MockStorageService mockStorage;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApiClient = _MockApiClient();
    mockStorage = _MockStorageService();
    repository = AuthRepositoryImpl(
      apiClient: mockApiClient,
      storageService: mockStorage,
    );
  });

  group('AuthRepositoryImpl.resetPassword', () {
    test('posts token + new_password and returns Success on 200', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/auth/reset-password',
          statusCode: 200,
          data: <String, dynamic>{'message': 'ok'},
        ),
      );

      final result = await repository.resetPassword('raw-token', 'newPass123');

      expect(result, isA<Success<void>>());

      final captured = verify(
        () => mockApiClient.post(
          '/auth/reset-password',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      // snake_case body — backend has NO camelCase alias here.
      expect(payload['token'], 'raw-token');
      expect(payload['new_password'], 'newPass123');
      expect(payload.containsKey('newPassword'), isFalse);
    });

    test('returns Failure on non-200 status', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response(
          path: '/auth/reset-password',
          statusCode: 204,
          data: null,
        ),
      );

      final result = await repository.resetPassword('t', 'newPass123');

      expect(result, isA<Failure<void>>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('maps DioException (400 invalid token) to Failure', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          response: _response(
            path: '/auth/reset-password',
            statusCode: 400,
            data: <String, dynamic>{'detail': 'Invalid or expired token'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.resetPassword('bad', 'newPass123');

      expect(result, isA<Failure<void>>());
    });
  });
}
