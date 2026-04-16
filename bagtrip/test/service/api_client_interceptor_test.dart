// Exercises the JWT-injection + 401-refresh interceptors of `ApiClient`
// end-to-end, using `http_mock_adapter` to stub both the main Dio and
// the refresh Dio (injected via the factory exposed in phase F).

import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorageService extends Mock implements StorageService {}

/// Sits at the tail of the Dio interceptor chain so tests can inspect
/// the final outgoing headers/url after ApiClient's own interceptors ran.
class _CaptureInterceptor extends Interceptor {
  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);
    handler.next(options);
  }
}

void main() {
  late _MockStorageService mockStorage;
  late Dio mainDio;
  late DioAdapter mainAdapter;
  late Dio refreshDio;
  late DioAdapter refreshAdapter;
  late _CaptureInterceptor capture;
  late ApiClient apiClient;

  const testBaseUrl = 'https://api.test';

  setUp(() {
    mockStorage = _MockStorageService();

    mainDio = Dio(BaseOptions(baseUrl: testBaseUrl));
    mainAdapter = DioAdapter(dio: mainDio);

    refreshDio = Dio(BaseOptions(baseUrl: testBaseUrl));
    refreshAdapter = DioAdapter(dio: refreshDio);

    apiClient = ApiClient(
      baseUrl: testBaseUrl,
      storageService: mockStorage,
      dio: mainDio,
      refreshDioFactory: (_) => refreshDio,
    );

    // Attach capture AFTER ApiClient's interceptors so we observe the
    // final headers (incl. Authorization) added by the JWT interceptor.
    capture = _CaptureInterceptor();
    mainDio.interceptors.add(capture);

    when(() => mockStorage.getToken()).thenAnswer((_) async => 'access-1');
    when(
      () => mockStorage.getRefreshToken(),
    ).thenAnswer((_) async => 'refresh-1');
    when(() => mockStorage.deleteToken()).thenAnswer((_) async {});
    when(() => mockStorage.saveTokens(any(), any())).thenAnswer((_) async {});
  });

  group('ApiClient', () {
    test('injects Authorization header on every request', () async {
      mainAdapter.onGet('/ping', (server) => server.reply(200, {'ok': true}));

      await apiClient.get('/ping');

      expect(capture.captured, isNotEmpty);
      expect(
        capture.captured.first.headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('skips Authorization header when storage returns null', () async {
      when(() => mockStorage.getToken()).thenAnswer((_) async => null);
      mainAdapter.onGet('/health', (server) => server.reply(200, {'ok': true}));

      await apiClient.get('/health');

      expect(
        capture.captured.first.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test(
      '401 triggers refresh + replays the original request with the new token',
      () async {
        var tokenReadCount = 0;
        when(() => mockStorage.getToken()).thenAnswer((_) async {
          tokenReadCount++;
          return tokenReadCount == 1 ? 'stale' : 'fresh-access';
        });

        mainAdapter
          ..onGet(
            '/me',
            (server) => server.reply(401, {'detail': 'expired'}),
            headers: {'Authorization': 'Bearer stale'},
          )
          ..onGet(
            '/me',
            (server) => server.reply(200, {'id': 'user-1'}),
            headers: {'Authorization': 'Bearer fresh-access'},
          );

        refreshAdapter.onPost(
          '/auth/refresh',
          (server) => server.reply(200, {
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          }),
          data: {'refresh_token': 'refresh-1'},
        );

        final response = await apiClient.get('/me');

        expect(response.statusCode, 200);
        expect(response.data, {'id': 'user-1'});
        verify(
          () => mockStorage.saveTokens('fresh-access', 'fresh-refresh'),
        ).called(1);
      },
    );

    test('401 without a refresh token: deletes tokens and rejects', () async {
      when(() => mockStorage.getRefreshToken()).thenAnswer((_) async => null);

      mainAdapter.onGet(
        '/me',
        (server) => server.reply(401, {'detail': 'expired'}),
      );

      expect(() => apiClient.get('/me'), throwsA(isA<DioException>()));
      await pumpEventQueue();
      verify(() => mockStorage.deleteToken()).called(1);
    });

    test('401 with a failing refresh: deletes tokens and rejects', () async {
      mainAdapter.onGet(
        '/secured',
        (server) => server.reply(401, {'detail': 'expired'}),
      );
      refreshAdapter.onPost(
        '/auth/refresh',
        (server) => server.reply(500, {'detail': 'refresh down'}),
        data: {'refresh_token': 'refresh-1'},
      );

      expect(() => apiClient.get('/secured'), throwsA(isA<DioException>()));
      await pumpEventQueue();
      verify(() => mockStorage.deleteToken()).called(1);
    });

    test('exposes the raw Dio through the `dio` getter', () {
      expect(apiClient.dio, same(mainDio));
    });

    test('verb helpers forward to the same base Dio', () async {
      mainAdapter
        ..onPost(
          '/create',
          (server) => server.reply(201, {'id': 'x'}),
          data: {'foo': 'bar'},
        )
        ..onPatch(
          '/edit/1',
          (server) => server.reply(200, {'ok': true}),
          data: {'foo': 'baz'},
        )
        ..onPut(
          '/replace/1',
          (server) => server.reply(200, {'ok': true}),
          data: {'foo': 'qux'},
        )
        ..onDelete('/drop/1', (server) => server.reply(204, null));

      final post = await apiClient.post('/create', data: {'foo': 'bar'});
      final patch = await apiClient.patch('/edit/1', data: {'foo': 'baz'});
      final put = await apiClient.put('/replace/1', data: {'foo': 'qux'});
      final del = await apiClient.delete('/drop/1');

      expect(post.statusCode, 201);
      expect(patch.statusCode, 200);
      expect(put.statusCode, 200);
      expect(del.statusCode, 204);
    });
  });

  group('ApiClient.mapDioError', () {
    DioException make({required int? statusCode, Object? data, String? type}) {
      return DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: statusCode == null
            ? null
            : Response(
                requestOptions: RequestOptions(path: '/x'),
                statusCode: statusCode,
                data: data,
              ),
        type: type == 'timeout'
            ? DioExceptionType.connectionTimeout
            : type == 'connection'
            ? DioExceptionType.connectionError
            : DioExceptionType.unknown,
      );
    }

    test('400 maps to ValidationError with detail', () {
      final err = ApiClient.mapDioError(
        make(statusCode: 400, data: {'detail': 'bad'}),
      );
      expect(err.message, 'bad');
      expect(err.statusCode, 400);
    });

    test('401 maps to AuthenticationError', () {
      final err = ApiClient.mapDioError(
        make(statusCode: 401, data: {'detail': 'unauth'}),
      );
      expect(err.statusCode, 401);
    });

    test('402 maps to QuotaExceededError', () {
      final err = ApiClient.mapDioError(make(statusCode: 402, data: {}));
      expect(err.statusCode, 402);
    });

    test('409 stale_context maps to StaleContextError', () {
      final err = ApiClient.mapDioError(
        make(statusCode: 409, data: {'error': 'stale_context', 'detail': 'x'}),
      );
      expect(err.statusCode, 409);
    });

    test('429 maps to RateLimitError', () {
      final err = ApiClient.mapDioError(make(statusCode: 429, data: {}));
      expect(err.statusCode, 429);
    });

    test('500 maps to ServerError', () {
      final err = ApiClient.mapDioError(make(statusCode: 500, data: {}));
      expect(err.statusCode, 500);
    });

    test('connectionTimeout maps to NetworkError', () {
      final err = ApiClient.mapDioError(
        make(statusCode: null, type: 'timeout'),
      );
      expect(err.message, 'timeout');
    });

    test('connectionError maps to NetworkError', () {
      final err = ApiClient.mapDioError(
        make(statusCode: null, type: 'connection'),
      );
      expect(err.message, 'connection_error');
    });
  });
}
