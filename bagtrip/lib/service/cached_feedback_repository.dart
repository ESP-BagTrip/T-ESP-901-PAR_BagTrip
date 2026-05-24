import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';

class CachedFeedbackRepository implements FeedbackRepository {
  final FeedbackRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'feedback_cache';

  CachedFeedbackRepository({
    required FeedbackRepository remote,
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
    q.registerHandler('feedback:submitFeedback', (args) async {
      final result = await _remote.submitFeedback(
        args['tripId'] as String,
        overallRating: args['overallRating'] as int,
        highlights: args['highlights'] as String?,
        lowlights: args['lowlights'] as String?,
        wouldRecommend: args['wouldRecommend'] as bool,
        aiExperienceRating: args['aiExperienceRating'] as int?,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<TripFeedback>>> getFeedbacks(String tripId) async {
    final key = 'feedbacks:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getFeedbacks(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, {
          'items': data.map((f) => f.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      final items = (cached['items'] as List)
          .map(
            (e) => TripFeedback.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<TripFeedback>> submitFeedback(
    String tripId, {
    required int overallRating,
    String? highlights,
    String? lowlights,
    required bool wouldRecommend,
    int? aiExperienceRating,
  }) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'feedback',
          method: 'submitFeedback',
          arguments: {
            'tripId': tripId,
            'overallRating': overallRating,
            'highlights': highlights,
            'lowlights': lowlights,
            'wouldRecommend': wouldRecommend,
            'aiExperienceRating': aiExperienceRating,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.submitFeedback(
      tripId,
      overallRating: overallRating,
      highlights: highlights,
      lowlights: lowlights,
      wouldRecommend: wouldRecommend,
      aiExperienceRating: aiExperienceRating,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'feedbacks:$tripId');
  }
}
