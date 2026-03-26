import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/subscription_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('SubscriptionRepositoryImpl', () {
    late MockApiClient mockApiClient;
    late SubscriptionRepositoryImpl repository;

    setUp(() {
      mockApiClient = MockApiClient();
      repository = SubscriptionRepositoryImpl(apiClient: mockApiClient);
    });

    group('getCheckoutUrl', () {
      test('returns success with URL when response contains url', () async {
        when(() => mockApiClient.post('/subscription/checkout')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/checkout'),
            statusCode: 200,
            data: <String, dynamic>{
              'url': 'https://checkout.stripe.com/session/cs_test_123',
            },
          ),
        );

        final result = await repository.getCheckoutUrl();

        expect(result, isA<Success<String>>());
        expect(
          (result as Success<String>).data,
          'https://checkout.stripe.com/session/cs_test_123',
        );
      });

      test(
        'returns failure with ServerError when url key is missing',
        () async {
          when(() => mockApiClient.post('/subscription/checkout')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/subscription/checkout'),
              statusCode: 200,
              data: <String, dynamic>{'session_id': 'cs_test_123'},
            ),
          );

          final result = await repository.getCheckoutUrl();

          expect(result, isA<Failure<String>>());
          final failure = result as Failure<String>;
          expect(failure.error, isA<ServerError>());
          expect(failure.error.message, contains('missing url'));
        },
      );

      test('returns failure with ServerError when url is null', () async {
        when(() => mockApiClient.post('/subscription/checkout')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/checkout'),
            statusCode: 200,
            data: <String, dynamic>{'url': null},
          ),
        );

        final result = await repository.getCheckoutUrl();

        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        expect(failure.error, isA<ServerError>());
      });

      test(
        'returns failure with ServerError when response is not a Map',
        () async {
          when(() => mockApiClient.post('/subscription/checkout')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/subscription/checkout'),
              statusCode: 200,
              data: 'plain text response',
            ),
          );

          final result = await repository.getCheckoutUrl();

          expect(result, isA<Failure<String>>());
          final failure = result as Failure<String>;
          expect(failure.error, isA<ServerError>());
        },
      );

      test('DioException maps to appropriate AppError', () async {
        when(() => mockApiClient.post('/subscription/checkout')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/subscription/checkout'),
            response: Response(
              requestOptions: RequestOptions(path: '/subscription/checkout'),
              statusCode: 401,
              data: {'detail': 'Unauthorized'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final result = await repository.getCheckoutUrl();

        expect(result, isA<Failure<String>>());
        final failure = result as Failure<String>;
        expect(failure.error, isA<AuthenticationError>());
      });
    });

    group('getPortalUrl', () {
      test('returns success with URL when response contains url', () async {
        when(() => mockApiClient.post('/subscription/portal')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/portal'),
            statusCode: 200,
            data: <String, dynamic>{
              'url': 'https://billing.stripe.com/session/bps_test_456',
            },
          ),
        );

        final result = await repository.getPortalUrl();

        expect(result, isA<Success<String>>());
        expect(
          (result as Success<String>).data,
          'https://billing.stripe.com/session/bps_test_456',
        );
      });

      test(
        'returns failure with ServerError when url key is missing',
        () async {
          when(() => mockApiClient.post('/subscription/portal')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/subscription/portal'),
              statusCode: 200,
              data: <String, dynamic>{'redirect': '/dashboard'},
            ),
          );

          final result = await repository.getPortalUrl();

          expect(result, isA<Failure<String>>());
          final failure = result as Failure<String>;
          expect(failure.error, isA<ServerError>());
          expect(failure.error.message, contains('missing url'));
        },
      );
    });

    group('getStatus', () {
      test('returns success with status map', () async {
        when(() => mockApiClient.get('/subscription/status')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/status'),
            statusCode: 200,
            data: <String, dynamic>{
              'plan': 'PREMIUM',
              'status': 'active',
              'expires_at': '2025-12-31T23:59:59.000',
            },
          ),
        );

        final result = await repository.getStatus();

        expect(result, isA<Success<Map<String, dynamic>>>());
        final data = (result as Success<Map<String, dynamic>>).data;
        expect(data['plan'], 'PREMIUM');
        expect(data['status'], 'active');
      });

      test('returns failure when response is not a Map', () async {
        when(() => mockApiClient.get('/subscription/status')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/status'),
            statusCode: 200,
            data: 'not-a-map',
          ),
        );

        final result = await repository.getStatus();

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final failure = result as Failure<Map<String, dynamic>>;
        expect(failure.error, isA<ServerError>());
      });

      test('generic exception maps to UnknownError', () async {
        when(
          () => mockApiClient.get('/subscription/status'),
        ).thenThrow(Exception('Unexpected crash'));

        final result = await repository.getStatus();

        expect(result, isA<Failure<Map<String, dynamic>>>());
        final failure = result as Failure<Map<String, dynamic>>;
        expect(failure.error, isA<UnknownError>());
      });
    });
  });
}
