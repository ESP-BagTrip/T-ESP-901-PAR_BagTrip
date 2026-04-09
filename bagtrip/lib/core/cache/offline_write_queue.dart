import 'dart:async';

import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';

class PendingWriteOperation {
  final String id;
  final String repository;
  final String method;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;

  PendingWriteOperation({
    required this.id,
    required this.repository,
    required this.method,
    required this.arguments,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'repository': repository,
    'method': method,
    'arguments': arguments,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingWriteOperation.fromJson(Map<String, dynamic> json) =>
      PendingWriteOperation(
        id: json['id'] as String,
        repository: json['repository'] as String,
        method: json['method'] as String,
        arguments: Map<String, dynamic>.from(json['arguments'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

typedef ReplayHandler = Future<bool> Function(Map<String, dynamic> arguments);

class OfflineWriteQueue {
  final CacheService _cache;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;

  static const _box = 'offline_write_queue';
  static const _indexKey = 'pending_operations';

  final _pendingCountController = StreamController<int>.broadcast();
  final Map<String, ReplayHandler> _handlers = {};

  OfflineWriteQueue({
    required CacheService cache,
    required ConnectivityService connectivity,
  }) : _cache = cache,
       _connectivity = connectivity;

  Stream<int> get pendingCount => _pendingCountController.stream;

  void registerHandler(String key, ReplayHandler handler) {
    _handlers[key] = handler;
  }

  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        replay();
      }
    });
  }

  Future<void> enqueue(PendingWriteOperation operation) async {
    final operations = await _loadOperations();
    operations.add(operation);
    await _saveOperations(operations);
    _pendingCountController.add(operations.length);
  }

  Future<List<PendingWriteOperation>> getPending() async {
    return _loadOperations();
  }

  Future<void> replay() async {
    final operations = await _loadOperations();
    if (operations.isEmpty) return;

    final remaining = <PendingWriteOperation>[];
    var stopped = false;

    for (final op in operations) {
      if (stopped) {
        remaining.add(op);
        continue;
      }

      final handlerKey = '${op.repository}:${op.method}';
      final handler = _handlers[handlerKey];
      if (handler == null) {
        remaining.add(op);
        stopped = true;
        continue;
      }

      final success = await handler(op.arguments);
      if (!success) {
        remaining.add(op);
        stopped = true;
      }
    }

    await _saveOperations(remaining);
    _pendingCountController.add(remaining.length);
  }

  Future<void> clear() async {
    await _saveOperations([]);
    _pendingCountController.add(0);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _pendingCountController.close();
  }

  // --------------- Persistence ---------------

  Future<List<PendingWriteOperation>> _loadOperations() async {
    final cached = await _cache.get(_box, _indexKey);
    if (cached == null) return [];
    final items = cached['items'] as List?;
    if (items == null) return [];
    return items
        .map(
          (e) => PendingWriteOperation.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _saveOperations(List<PendingWriteOperation> operations) async {
    await _cache.put(_box, _indexKey, {
      'items': operations.map((o) => o.toJson()).toList(),
    });
  }
}
