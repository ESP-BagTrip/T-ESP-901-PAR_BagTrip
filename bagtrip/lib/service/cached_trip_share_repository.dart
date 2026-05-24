import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';

class CachedTripShareRepository implements TripShareRepository {
  final TripShareRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'trip_share_cache';

  CachedTripShareRepository({
    required TripShareRepository remote,
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
    q.registerHandler('tripShare:createShare', (args) async {
      final result = await _remote.createShare(
        args['tripId'] as String,
        email: args['email'] as String,
        message: args['message'] as String?,
        role: args['role'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('tripShare:deleteShare', (args) async {
      final result = await _remote.deleteShare(
        args['tripId'] as String,
        args['shareId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<TripShare>>> getSharesByTrip(String tripId) async {
    final key = 'shares:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getSharesByTrip(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, {
          'items': data.map((s) => s.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      final items = (cached['items'] as List)
          .map((e) => TripShare.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<TripShare>> createShare(
    String tripId, {
    required String email,
    String? message,
    String role = 'VIEWER',
  }) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'tripShare',
          method: 'createShare',
          arguments: {
            'tripId': tripId,
            'email': email,
            'message': message,
            'role': role,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createShare(
      tripId,
      email: email,
      message: message,
      role: role,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteShare(String tripId, String shareId) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'tripShare',
          method: 'deleteShare',
          arguments: {'tripId': tripId, 'shareId': shareId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteShare(tripId, shareId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'shares:$tripId');
  }
}
