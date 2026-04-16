// Tests the StorageService wrapper over FlutterSecureStorage by intercepting
// the underlying MethodChannel with an in-memory fake.

import 'package:bagtrip/service/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> fakeStore;
  late StorageService service;

  setUp(() {
    fakeStore = <String, String>{};
    service = StorageService();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          final key = call.arguments is Map
              ? call.arguments['key'] as String?
              : null;
          switch (call.method) {
            case 'write':
              fakeStore[key!] = call.arguments['value'] as String;
              return null;
            case 'read':
              return fakeStore[key];
            case 'readAll':
              return Map<String, String>.from(fakeStore);
            case 'containsKey':
              return fakeStore.containsKey(key);
            case 'delete':
              fakeStore.remove(key);
              return null;
            case 'deleteAll':
              fakeStore.clear();
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('StorageService', () {
    test('saveAccessToken + getAccessToken round-trip', () async {
      await service.saveAccessToken('access-123');
      expect(await service.getAccessToken(), 'access-123');
    });

    test('saveRefreshToken + getRefreshToken round-trip', () async {
      await service.saveRefreshToken('refresh-abc');
      expect(await service.getRefreshToken(), 'refresh-abc');
    });

    test('saveTokens writes both keys at once', () async {
      await service.saveTokens('A', 'R');
      expect(await service.getAccessToken(), 'A');
      expect(await service.getRefreshToken(), 'R');
    });

    test('getToken prefers access_token when present', () async {
      await service.saveAccessToken('fresh');
      fakeStore['jwt_token'] = 'legacy';
      expect(await service.getToken(), 'fresh');
    });

    test(
      'getToken falls back to legacy jwt_token when access_token is absent',
      () async {
        fakeStore['jwt_token'] = 'legacy';
        expect(await service.getToken(), 'legacy');
      },
    );

    test('saveToken writes under the modern access_token key', () async {
      await service.saveToken('t');
      expect(fakeStore['access_token'], 't');
    });

    test('deleteToken clears legacy + access + refresh keys', () async {
      fakeStore['jwt_token'] = 'legacy';
      await service.saveTokens('A', 'R');
      await service.deleteToken();
      expect(fakeStore.containsKey('jwt_token'), isFalse);
      expect(fakeStore.containsKey('access_token'), isFalse);
      expect(fakeStore.containsKey('refresh_token'), isFalse);
    });

    test('saveUser + getUser round-trip', () async {
      await service.saveUser('{"id":"u"}');
      expect(await service.getUser(), '{"id":"u"}');
    });

    test('clearAll removes every key', () async {
      await service.saveTokens('A', 'R');
      await service.saveUser('payload');
      await service.clearAll();
      expect(fakeStore.isEmpty, isTrue);
    });

    test('tokens are null when absent', () async {
      expect(await service.getAccessToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getToken(), isNull);
      expect(await service.getUser(), isNull);
    });
  });
}
