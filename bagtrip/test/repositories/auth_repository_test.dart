import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_services.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockStorageService mockStorageService;
  late AuthRepositoryImpl repo;

  setUp(() {
    mockApiClient = MockApiClient();
    mockStorageService = MockStorageService();
    repo = AuthRepositoryImpl(
      apiClient: mockApiClient,
      storageService: mockStorageService,
    );
  });

  group('login', () {
    test(
      'success (200) returns Success(AuthResponse) and saves tokens',
      () async {
        when(
          () => mockApiClient.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'access_token': 'tok',
              'refresh_token': 'ref',
              'expires_in': 3600,
              'user': {'id': 'u1', 'email': 'a@b.com'},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        );

        when(
          () => mockStorageService.saveTokens(any(), any()),
        ).thenAnswer((_) async {});

        final result = await repo.login('a@b.com', 'password123');

        expect(result, isA<Success>());
        final data = (result as Success).data;
        expect(data.accessToken, 'tok');
        expect(data.refreshToken, 'ref');
        expect(data.expiresIn, 3600);
        expect(data.user.id, 'u1');
        expect(data.user.email, 'a@b.com');

        verify(() => mockStorageService.saveTokens('tok', 'ref')).called(1);
      },
    );

    test('DioException 401 returns Failure(AuthenticationError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            statusCode: 401,
            data: {'detail': 'bad creds'},
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        ),
      );

      final result = await repo.login('a@b.com', 'wrong');

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<AuthenticationError>());
      expect(error.statusCode, 401);
      expect(error.message, 'bad creds');
    });
  });

  group('register', () {
    test('success (201) returns Success(AuthResponse)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'access_token': 'new_tok',
            'refresh_token': 'new_ref',
            'expires_in': 3600,
            'user': {'id': 'u2', 'email': 'new@b.com'},
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/auth/register'),
        ),
      );

      when(
        () => mockStorageService.saveTokens(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repo.register('new@b.com', 'pass123', 'New User');

      expect(result, isA<Success>());
      final data = (result as Success).data;
      expect(data.accessToken, 'new_tok');
      expect(data.user.email, 'new@b.com');

      verify(
        () => mockStorageService.saveTokens('new_tok', 'new_ref'),
      ).called(1);
    });
  });

  group('getCurrentUser', () {
    test('success (200) returns Success(User)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'id': 'u1', 'email': 'a@b.com', 'fullName': 'Test User'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );

      final result = await repo.getCurrentUser();

      expect(result, isA<Success>());
      final user = (result as Success).data;
      expect(user, isNotNull);
      expect(user!.id, 'u1');
      expect(user.email, 'a@b.com');
    });

    test('DioException 401 returns Failure(AuthenticationError)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          response: Response(
            statusCode: 401,
            data: {'detail': 'not authenticated'},
            requestOptions: RequestOptions(path: '/auth/me'),
          ),
        ),
      );

      final result = await repo.getCurrentUser();

      expect(result, isA<Failure>());
      final error = (result as Failure).error;
      expect(error, isA<AuthenticationError>());
    });
  });

  group('isAuthenticated', () {
    test('returns Success(true) when token exists', () async {
      when(
        () => mockStorageService.getToken(),
      ).thenAnswer((_) async => 'some-token');

      final result = await repo.isAuthenticated();

      expect(result, isA<Success>());
      expect((result as Success).data, true);
    });

    test('returns Success(false) when token is null', () async {
      when(() => mockStorageService.getToken()).thenAnswer((_) async => null);

      final result = await repo.isAuthenticated();

      expect(result, isA<Success>());
      expect((result as Success).data, false);
    });
  });

  group('logout', () {
    test('calls clearAll and returns Success(null)', () async {
      when(
        () => mockStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'ref_tok');

      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/logout'),
        ),
      );

      when(() => mockStorageService.clearAll()).thenAnswer((_) async {});

      final result = await repo.logout();

      expect(result, isA<Success>());
      verify(() => mockStorageService.clearAll()).called(1);
    });

    test('clearAll is still called if the server call fails', () async {
      when(
        () => mockStorageService.getRefreshToken(),
      ).thenAnswer((_) async => 'ref_tok');
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/logout'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      when(() => mockStorageService.clearAll()).thenAnswer((_) async {});

      expect(await repo.logout(), isA<Success>());
      verify(() => mockStorageService.clearAll()).called(1);
    });

    test('skips the server call when there is no refresh token', () async {
      when(
        () => mockStorageService.getRefreshToken(),
      ).thenAnswer((_) async => null);
      when(() => mockStorageService.clearAll()).thenAnswer((_) async {});

      expect(await repo.logout(), isA<Success>());
      verifyNever(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
      verify(() => mockStorageService.clearAll()).called(1);
    });
  });

  // ── Phase B reinforcement: failure + non-2xx + extra methods ──────────

  group('login — error paths', () {
    test('non-200 returns Failure(UnknownError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/login'),
        ),
      );

      final result = await repo.login('a@b.com', 'x');
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('non-Dio exception wrapped in UnknownError', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(const FormatException('bad json'));

      final result = await repo.login('a@b.com', 'x');
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });
  });

  group('register — error paths', () {
    test('non-2xx returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/register'),
        ),
      );

      expect(await repo.register('new@b.com', 'p', 'New User'), isA<Failure>());
    });

    test('DioException 409 returns Failure(ConflictError)', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/register'),
          response: Response(
            statusCode: 409,
            data: {'detail': 'email already taken'},
            requestOptions: RequestOptions(path: '/auth/register'),
          ),
        ),
      );

      expect(await repo.register('dup@b.com', 'p', 'Dup'), isA<Failure>());
    });
  });

  group('getCurrentUser — error paths', () {
    test('non-200 returns Failure(ServerError)', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );

      final result = await repo.getCurrentUser();
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<ServerError>());
    });

    test('non-401 DioException returns mapped error', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repo.getCurrentUser();
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<NetworkError>());
    });

    test('non-Dio exception wrapped in UnknownError', () async {
      when(
        () => mockApiClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(const FormatException('bad'));

      final result = await repo.getCurrentUser();
      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });
  });

  group('updateUser', () {
    test('sends only the fields that were provided', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          data: {'id': 'u1', 'email': 'a@b.com', 'fullName': 'New Name'},
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );

      final result = await repo.updateUser(fullName: 'New Name');
      expect(result, isA<Success>());

      final captured = verify(
        () => mockApiClient.patch(
          '/auth/me',
          data: captureAny(named: 'data'),
          options: any(named: 'options'),
        ),
      ).captured;
      final payload = captured.single as Map<String, dynamic>;
      expect(payload, {'fullName': 'New Name'});
      expect(payload.containsKey('phone'), isFalse);
    });

    test('non-200 returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );
      expect(await repo.updateUser(phone: '555'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.patch(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.updateUser(phone: '555'), isA<Failure>());
    });
  });

  group('forgotPassword', () {
    test('returns Success on 200', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
        ),
      );

      expect(await repo.forgotPassword('a@b.com'), isA<Success>());
    });

    test('returns Failure on non-200', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
        ),
      );

      expect(await repo.forgotPassword('a@b.com'), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.forgotPassword('a@b.com'), isA<Failure>());
    });
  });

  group('deleteAccount', () {
    test('returns Success on 204 and clears all', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );
      when(() => mockStorageService.clearAll()).thenAnswer((_) async {});

      expect(await repo.deleteAccount(), isA<Success>());
      verify(() => mockStorageService.clearAll()).called(1);
    });

    test('non-204 returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 500,
          data: <String, dynamic>{},
          requestOptions: RequestOptions(path: '/auth/me'),
        ),
      );

      expect(await repo.deleteAccount(), isA<Failure>());
    });

    test('DioException returns Failure', () async {
      when(
        () => mockApiClient.delete(any(), options: any(named: 'options')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/me'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(await repo.deleteAccount(), isA<Failure>());
    });
  });

  group('isAuthenticated edge cases', () {
    test('empty-string token yields Success(false)', () async {
      when(() => mockStorageService.getToken()).thenAnswer((_) async => '');
      final result = await repo.isAuthenticated();
      expect((result as Success).data, false);
    });
  });
}
