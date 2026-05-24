import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/suggested_baggage_item.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';

class CachedBaggageRepository implements BaggageRepository {
  final BaggageRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'baggage_cache';

  CachedBaggageRepository({
    required BaggageRepository remote,
    required CacheService cache,
    required ConnectivityService connectivity,
    OfflineWriteQueue? queue,
  }) : _remote = remote,
       _cache = cache,
       _connectivity = connectivity,
       _queue = queue {
    _registerReplayHandlers();
  }

  void _registerReplayHandlers() {
    final q = _queue;
    if (q == null) return;
    q.registerHandler('baggage:createBaggageItem', (args) async {
      final result = await _remote.createBaggageItem(
        args['tripId'] as String,
        name: args['name'] as String,
        quantity: args['quantity'] as int?,
        isPacked: args['isPacked'] as bool?,
        category: args['category'] as String?,
        notes: args['notes'] as String?,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('baggage:updateBaggageItem', (args) async {
      final result = await _remote.updateBaggageItem(
        args['tripId'] as String,
        args['baggageItemId'] as String,
        Map<String, dynamic>.from(args['updates'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('baggage:deleteBaggageItem', (args) async {
      final result = await _remote.deleteBaggageItem(
        args['tripId'] as String,
        args['baggageItemId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<BaggageItem>>> getByTrip(String tripId) async {
    final key = 'baggage:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getByTrip(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, {
          'items': data.map((b) => b.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      final items = (cached['items'] as List)
          .map((e) => BaggageItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  @override
  Future<Result<List<SuggestedBaggageItem>>> suggestBaggage(
    String tripId,
  ) async {
    return _remote.suggestBaggage(tripId);
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<BaggageItem>> createBaggageItem(
    String tripId, {
    required String name,
    int? quantity,
    bool? isPacked,
    String? category,
    String? notes,
  }) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'baggage',
          method: 'createBaggageItem',
          arguments: {
            'tripId': tripId,
            'name': name,
            'quantity': quantity,
            'isPacked': isPacked,
            'category': category,
            'notes': notes,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createBaggageItem(
      tripId,
      name: name,
      quantity: quantity,
      isPacked: isPacked,
      category: category,
      notes: notes,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<BaggageItem>> updateBaggageItem(
    String tripId,
    String baggageItemId,
    Map<String, dynamic> updates,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'baggage',
          method: 'updateBaggageItem',
          arguments: {
            'tripId': tripId,
            'baggageItemId': baggageItemId,
            'updates': updates,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.updateBaggageItem(
      tripId,
      baggageItemId,
      updates,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteBaggageItem(
    String tripId,
    String baggageItemId,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'baggage',
          method: 'deleteBaggageItem',
          arguments: {'tripId': tripId, 'baggageItemId': baggageItemId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteBaggageItem(tripId, baggageItemId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'baggage:$tripId');
  }
}
