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

    // ── Native PaymentSheet flow ─────────────────────────────────────

    group('start (deferred bootstrap)', () {
      test('parses {customer, ephemeralKey, amount, currency}', () async {
        when(() => mockApiClient.post('/subscription/start')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/start'),
            statusCode: 200,
            data: <String, dynamic>{
              'customer': 'cus_123',
              'ephemeral_key': 'ek_secret_abc',
              'amount': 999,
              'currency': 'eur',
            },
          ),
        );

        final result = await repository.start();
        expect(result, isA<Success<dynamic>>());
        final params = (result as Success).data;
        expect(params.customer, 'cus_123');
        expect(params.ephemeralKey, 'ek_secret_abc');
        expect(params.amount, 999);
        expect(params.currency, 'eur');
      });

      test('returns ServerError on malformed response', () async {
        when(() => mockApiClient.post('/subscription/start')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/start'),
            statusCode: 200,
            data: 'not-a-map',
          ),
        );
        final result = await repository.start();
        expect(result, isA<Failure<dynamic>>());
        expect((result as Failure).error, isA<ServerError>());
      });
    });

    group('confirmSubscription', () {
      test('POSTs paymentMethodId and returns the client_secret', () async {
        when(
          () => mockApiClient.post(
            '/subscription/confirm',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/confirm'),
            statusCode: 200,
            data: <String, dynamic>{
              'subscription_id': 'sub_999',
              'client_secret': 'pi_secret_xyz',
            },
          ),
        );

        final result = await repository.confirmSubscription('pm_card_visa');
        expect(result, isA<Success<String>>());
        expect((result as Success<String>).data, 'pi_secret_xyz');
        verify(
          () => mockApiClient.post(
            '/subscription/confirm',
            data: {'paymentMethodId': 'pm_card_visa'},
          ),
        ).called(1);
      });

      test('returns ServerError when client_secret is missing', () async {
        when(
          () => mockApiClient.post(
            '/subscription/confirm',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/subscription/confirm'),
            statusCode: 200,
            data: <String, dynamic>{'subscription_id': 'sub_x'},
          ),
        );
        final result = await repository.confirmSubscription('pm_x');
        expect(result, isA<Failure<String>>());
        expect((result as Failure<String>).error, isA<ServerError>());
      });
    });

    group('startPaymentMethodUpdate', () {
      test('parses SetupIntent + ephemeral key trio', () async {
        when(
          () => mockApiClient.post('/subscription/payment-method/setup'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/subscription/payment-method/setup',
            ),
            statusCode: 200,
            data: <String, dynamic>{
              'setup_intent_client_secret': 'seti_secret',
              'ephemeral_key': 'ek_secret',
              'customer': 'cus_123',
            },
          ),
        );

        final result = await repository.startPaymentMethodUpdate();
        expect(result, isA<Success<dynamic>>());
        final params = (result as Success).data;
        expect(params.setupIntentClientSecret, 'seti_secret');
        expect(params.ephemeralKey, 'ek_secret');
      });
    });

    group('attachPaymentMethod', () {
      test(
        'POSTs paymentMethodId in camelCase as the backend expects',
        () async {
          when(
            () => mockApiClient.post(
              '/subscription/payment-method/attach',
              data: any(named: 'data'),
            ),
          ).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(
                path: '/subscription/payment-method/attach',
              ),
              statusCode: 200,
              data: <String, dynamic>{'status': 'attached'},
            ),
          );

          final result = await repository.attachPaymentMethod('pm_xyz');
          expect(result, isA<Success<void>>());
          // Body matches the backend's `Body(..., alias='paymentMethodId')`.
          verify(
            () => mockApiClient.post(
              '/subscription/payment-method/attach',
              data: {'paymentMethodId': 'pm_xyz'},
            ),
          ).called(1);
        },
      );
    });
  });
}
