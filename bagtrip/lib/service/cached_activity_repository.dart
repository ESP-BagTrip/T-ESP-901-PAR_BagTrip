import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/repositories/activity_repository.dart';

class CachedActivityRepository implements ActivityRepository {
  final ActivityRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'activities_cache';

  CachedActivityRepository({
    required ActivityRepository remote,
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
    q.registerHandler('activity:createActivity', (args) async {
      final result = await _remote.createActivity(
        args['tripId'] as String,
        Map<String, dynamic>.from(args['data'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('activity:updateActivity', (args) async {
      final result = await _remote.updateActivity(
        args['tripId'] as String,
        args['activityId'] as String,
        Map<String, dynamic>.from(args['updates'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('activity:deleteActivity', (args) async {
      final result = await _remote.deleteActivity(
        args['tripId'] as String,
        args['activityId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<Activity>>> getActivities(String tripId) async {
    final key = 'activities:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getActivities(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, {
          'items': data.map((a) => a.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      final items = (cached['items'] as List)
          .map((e) => Activity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  @override
  Future<Result<PaginatedResponse<Activity>>> getActivitiesPaginated(
    String tripId, {
    int page = 1,
    int limit = 20,
  }) async {
    return _remote.getActivitiesPaginated(tripId, page: page, limit: limit);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> suggestActivities(
    String tripId, {
    int? day,
  }) async {
    return _remote.suggestActivities(tripId, day: day);
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<Activity>> createActivity(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'activity',
          method: 'createActivity',
          arguments: {'tripId': tripId, 'data': data},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createActivity(tripId, data);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<Activity>> updateActivity(
    String tripId,
    String activityId,
    Map<String, dynamic> updates,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'activity',
          method: 'updateActivity',
          arguments: {
            'tripId': tripId,
            'activityId': activityId,
            'updates': updates,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.updateActivity(tripId, activityId, updates);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteActivity(String tripId, String activityId) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'activity',
          method: 'deleteActivity',
          arguments: {'tripId': tripId, 'activityId': activityId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteActivity(tripId, activityId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<List<Activity>>> batchUpdateActivities(
    String tripId,
    List<String> activityIds,
    Map<String, dynamic> updates,
  ) async {
    final result = await _remote.batchUpdateActivities(
      tripId,
      activityIds,
      updates,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'activities:$tripId');
  }
}
