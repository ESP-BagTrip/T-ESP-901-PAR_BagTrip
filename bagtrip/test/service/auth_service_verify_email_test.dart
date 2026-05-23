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

  group('AuthRepositoryImpl.verifyEmail', () {
    test(
      'posts token to /auth/verify-email and returns Success on 200',
      () async {
        when(
          () => mockApiClient.post(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => _response(
            path: '/auth/verify-email',
            statusCode: 200,
            data: <String, dynamic>{'message': 'verified'},
          ),
        );

        final result = await repository.verifyEmail('raw-token');

        expect(result, isA<Success<void>>());

        final captured = verify(
          () => mockApiClient.post(
            '/auth/verify-email',
            data: captureAny(named: 'data'),
          ),
        ).captured;
        final payload = captured.single as Map<String, dynamic>;
        expect(payload['token'], 'raw-token');
      },
    );

    test('returns Failure on non-200 status', () async {
      when(
        () => mockApiClient.post(any(), data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            _response(path: '/auth/verify-email', statusCode: 204, data: null),
      );

      final result = await repository.verifyEmail('t');

      expect(result, isA<Failure<void>>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('maps DioException (400 invalid token) to Failure', () async {
      when(() => mockApiClient.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/verify-email'),
          response: _response(
            path: '/auth/verify-email',
            statusCode: 400,
            data: <String, dynamic>{'detail': 'Invalid or expired token'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.verifyEmail('bad');

      expect(result, isA<Failure<void>>());
    });
  });

  group('AuthRepositoryImpl.resendVerification', () {
    test(
      'posts to /auth/resend-verification with no body and returns Success',
      () async {
        when(() => mockApiClient.post(any())).thenAnswer(
          (_) async => _response(
            path: '/auth/resend-verification',
            statusCode: 200,
            data: <String, dynamic>{'message': 'sent'},
          ),
        );

        final result = await repository.resendVerification();

        expect(result, isA<Success<void>>());
        verify(() => mockApiClient.post('/auth/resend-verification')).called(1);
      },
    );

    test('returns Failure on non-200 status', () async {
      when(() => mockApiClient.post(any())).thenAnswer(
        (_) async => _response(
          path: '/auth/resend-verification',
          statusCode: 202,
          data: null,
        ),
      );

      final result = await repository.resendVerification();

      expect(result, isA<Failure<void>>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('maps DioException to Failure', () async {
      when(() => mockApiClient.post(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/resend-verification'),
          response: _response(
            path: '/auth/resend-verification',
            statusCode: 429,
            data: <String, dynamic>{'detail': 'Too many requests'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.resendVerification();

      expect(result, isA<Failure<void>>());
    });
  });
}
