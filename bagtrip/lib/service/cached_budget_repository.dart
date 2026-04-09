import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/budget_estimation.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/repositories/budget_repository.dart';

class CachedBudgetRepository implements BudgetRepository {
  final BudgetRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'budget_cache';

  CachedBudgetRepository({
    required BudgetRepository remote,
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
    q.registerHandler('budget:createBudgetItem', (args) async {
      final result = await _remote.createBudgetItem(
        args['tripId'] as String,
        Map<String, dynamic>.from(args['data'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('budget:updateBudgetItem', (args) async {
      final result = await _remote.updateBudgetItem(
        args['tripId'] as String,
        args['itemId'] as String,
        Map<String, dynamic>.from(args['updates'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('budget:deleteBudgetItem', (args) async {
      final result = await _remote.deleteBudgetItem(
        args['tripId'] as String,
        args['itemId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<BudgetItem>>> getBudgetItems(String tripId) async {
    final key = 'budget_items:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getBudgetItems(tripId);
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
          .map((e) => BudgetItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  @override
  Future<Result<BudgetSummary>> getBudgetSummary(String tripId) async {
    final key = 'budget_summary:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getBudgetSummary(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, data.toJson());
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      return Success(BudgetSummary.fromJson(cached));
    }
    return const Failure(UnknownError('No cached data available'));
  }

  @override
  Future<Result<BudgetEstimation>> estimateBudget(String tripId) async {
    return _remote.estimateBudget(tripId);
  }

  @override
  Future<Result<void>> acceptBudgetEstimate(
    String tripId,
    double budgetTotal,
  ) async {
    final result = await _remote.acceptBudgetEstimate(tripId, budgetTotal);
    if (result is Success) {
      await _cache.delete(_box, 'budget_summary:$tripId');
    }
    return result;
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<BudgetItem>> createBudgetItem(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'budget',
          method: 'createBudgetItem',
          arguments: {'tripId': tripId, 'data': data},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createBudgetItem(tripId, data);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<BudgetItem>> updateBudgetItem(
    String tripId,
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'budget',
          method: 'updateBudgetItem',
          arguments: {'tripId': tripId, 'itemId': itemId, 'updates': updates},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.updateBudgetItem(tripId, itemId, updates);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteBudgetItem(String tripId, String itemId) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'budget',
          method: 'deleteBudgetItem',
          arguments: {'tripId': tripId, 'itemId': itemId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteBudgetItem(tripId, itemId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'budget_items:$tripId');
    await _cache.delete(_box, 'budget_summary:$tripId');
  }
}
