import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  late CacheService cacheService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    cacheService = CacheService();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('CacheService', () {
    test('put and get stores and retrieves data', () async {
      final data = {'name': 'Test Trip', 'id': '123'};
      await cacheService.put('test_box', 'key1', data);

      final result = await cacheService.get('test_box', 'key1');
      expect(result, isNotNull);
      expect(result!['name'], 'Test Trip');
      expect(result['id'], '123');
    });

    test('get returns null for missing key', () async {
      final result = await cacheService.get('test_box', 'nonexistent');
      expect(result, isNull);
    });

    test('get returns null for expired TTL', () async {
      final data = {'name': 'Old Data'};
      await cacheService.put('test_box', 'key1', data);

      final result = await cacheService.get(
        'test_box',
        'key1',
        ttl: Duration.zero,
      );
      expect(result, isNull);
    });

    test('get returns data within TTL', () async {
      final data = {'name': 'Fresh Data'};
      await cacheService.put('test_box', 'key1', data);

      final result = await cacheService.get(
        'test_box',
        'key1',
        ttl: const Duration(hours: 1),
      );
      expect(result, isNotNull);
      expect(result!['name'], 'Fresh Data');
    });

    test('delete removes a key', () async {
      await cacheService.put('test_box', 'key1', {'a': 1});
      await cacheService.delete('test_box', 'key1');

      final result = await cacheService.get('test_box', 'key1');
      expect(result, isNull);
    });

    test('clearBox clears all entries in a box', () async {
      await cacheService.put('test_box', 'key1', {'a': 1});
      await cacheService.put('test_box', 'key2', {'b': 2});
      await cacheService.clearBox('test_box');

      expect(await cacheService.get('test_box', 'key1'), isNull);
      expect(await cacheService.get('test_box', 'key2'), isNull);
    });

    test('clearAll removes all data', () async {
      await cacheService.put('box1', 'key1', {'a': 1});
      await cacheService.put('box2', 'key2', {'b': 2});
      await cacheService.clearAll();

      expect(await cacheService.get('box1', 'key1'), isNull);
      expect(await cacheService.get('box2', 'key2'), isNull);
    });

    test('put overwrites existing key', () async {
      await cacheService.put('test_box', 'key1', {'v': 1});
      await cacheService.put('test_box', 'key1', {'v': 2});

      final result = await cacheService.get('test_box', 'key1');
      expect(result!['v'], 2);
    });
  });
}
