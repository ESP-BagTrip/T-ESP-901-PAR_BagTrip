import 'dart:async';

import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockCacheService mockCache;
  late MockConnectivityService mockConnectivity;
  late OfflineWriteQueue queue;

  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 15));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockCache = MockCacheService();
    mockConnectivity = MockConnectivityService();
    queue = OfflineWriteQueue(cache: mockCache, connectivity: mockConnectivity);
  });

  tearDown(() async {
    await queue.dispose();
  });

  PendingWriteOperation makeOp({
    String id = '1',
    String repository = 'activity',
    String method = 'createActivity',
    Map<String, dynamic> arguments = const {'tripId': 'trip-1'},
  }) {
    return PendingWriteOperation(
      id: id,
      repository: repository,
      method: method,
      arguments: arguments,
      createdAt: DateTime(2026, 4),
    );
  }

  group('enqueue', () {
    test('persists operation to cache', () async {
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      await queue.enqueue(makeOp());

      verify(
        () => mockCache.put('offline_write_queue', 'pending_operations', any()),
      ).called(1);
    });

    test('emits pending count', () async {
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final counts = <int>[];
      queue.pendingCount.listen(counts.add);

      await queue.enqueue(makeOp());

      await Future<void>.delayed(Duration.zero);
      expect(counts, [1]);
    });
  });

  group('replay', () {
    test('replays operations in FIFO order and clears on success', () async {
      final op1 = makeOp();
      final op2 = makeOp(id: '2', method: 'deleteActivity');

      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [op1.toJson(), op2.toJson()],
        },
      );
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final replayedMethods = <String>[];
      queue.registerHandler('activity:createActivity', (args) async {
        replayedMethods.add('createActivity');
        return true;
      });
      queue.registerHandler('activity:deleteActivity', (args) async {
        replayedMethods.add('deleteActivity');
        return true;
      });

      await queue.replay();

      expect(replayedMethods, ['createActivity', 'deleteActivity']);
    });

    test('stops on first failure, keeps remaining', () async {
      final op1 = makeOp();
      final op2 = makeOp(id: '2', method: 'deleteActivity');

      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer(
        (_) async => {
          'items': [op1.toJson(), op2.toJson()],
        },
      );
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      queue.registerHandler('activity:createActivity', (args) async => false);
      queue.registerHandler('activity:deleteActivity', (args) async => true);

      await queue.replay();

      // Both should remain since we stop at first failure
      final captured =
          verify(
                () => mockCache.put(
                  'offline_write_queue',
                  'pending_operations',
                  captureAny(),
                ),
              ).captured.last
              as Map<String, dynamic>;
      final items = captured['items'] as List;
      expect(items.length, 2);
    });

    test('does nothing when queue is empty', () async {
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      await queue.replay();

      verifyNever(() => mockCache.put(any(), any(), any()));
    });
  });

  group('startListening', () {
    test('triggers replay when connectivity is restored', () async {
      final connectivityController = StreamController<bool>.broadcast();
      when(
        () => mockConnectivity.onConnectivityChanged,
      ).thenAnswer((_) => connectivityController.stream);
      when(
        () => mockCache.get(any(), any(), ttl: any(named: 'ttl')),
      ).thenAnswer((_) async => null);

      queue.startListening();

      connectivityController.add(true);
      await Future<void>.delayed(Duration.zero);

      // Replay was called (tried to load operations)
      verify(
        () => mockCache.get(
          'offline_write_queue',
          'pending_operations',
          ttl: any(named: 'ttl'),
        ),
      ).called(1);

      await connectivityController.close();
    });
  });

  group('clear', () {
    test('empties the queue', () async {
      when(() => mockCache.put(any(), any(), any())).thenAnswer((_) async {});

      final counts = <int>[];
      queue.pendingCount.listen(counts.add);

      await queue.clear();

      await Future<void>.delayed(Duration.zero);
      expect(counts, [0]);
    });
  });

  group('PendingWriteOperation', () {
    test('serializes and deserializes correctly', () {
      final op = makeOp(
        arguments: {
          'tripId': 'trip-1',
          'data': {'title': 'Test'},
        },
      );
      final json = op.toJson();
      final restored = PendingWriteOperation.fromJson(json);

      expect(restored.id, op.id);
      expect(restored.repository, op.repository);
      expect(restored.method, op.method);
      expect(restored.arguments['tripId'], 'trip-1');
      expect(restored.createdAt, op.createdAt);
    });
  });
}
