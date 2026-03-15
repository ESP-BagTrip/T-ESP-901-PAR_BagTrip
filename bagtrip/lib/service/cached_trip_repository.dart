import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/repositories/trip_repository.dart';

class CachedTripRepository implements TripRepository {
  final TripRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;

  static const _box = 'trips_cache';

  CachedTripRepository({
    required TripRepository remote,
    required CacheService cache,
    required ConnectivityService connectivity,
  }) : _remote = remote,
       _cache = cache,
       _connectivity = connectivity;

  // --------------- READ methods ---------------

  @override
  Future<Result<TripGrouped>> getGroupedTrips() async {
    if (_connectivity.isOnline) {
      final result = await _remote.getGroupedTrips();
      if (result case Success(:final data)) {
        await _cache.put(_box, 'grouped_trips', data.toJson());
      }
      return result;
    }
    return _fromCache('grouped_trips', TripGrouped.fromJson);
  }

  @override
  Future<Result<TripHome>> getTripHome(String tripId) async {
    final key = 'trip_home:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getTripHome(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, data.toJson());
      }
      return result;
    }
    return _fromCache(key, TripHome.fromJson);
  }

  @override
  Future<Result<Trip>> getTripById(String tripId) async {
    final key = 'trip:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getTripById(tripId);
      if (result case Success(:final data)) {
        await _cache.put(_box, key, data.toJson());
      }
      return result;
    }
    return _fromCache(key, Trip.fromJson);
  }

  @override
  Future<Result<List<Trip>>> getTrips() async {
    if (_connectivity.isOnline) {
      final result = await _remote.getTrips();
      if (result case Success(:final data)) {
        await _cache.put(_box, 'all_trips', {
          'items': data.map((t) => t.toJson()).toList(),
        });
      }
      return result;
    }
    final cached = await _cache.get(_box, 'all_trips');
    if (cached != null) {
      final items = (cached['items'] as List)
          .map((e) => Trip.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return Success(items);
    }
    return const Failure(NetworkError('No cached data available'));
  }

  @override
  Future<Result<PaginatedResponse<Trip>>> getTripsPaginated({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    // Paginated calls are not cached — always delegate to remote.
    return _remote.getTripsPaginated(page: page, limit: limit, status: status);
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<Trip>> createTrip({
    required String title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? destinationName,
    int? nbTravelers,
    String? coverImageUrl,
    double? budgetTotal,
    String? origin,
  }) async {
    final result = await _remote.createTrip(
      title: title,
      originIata: originIata,
      destinationIata: destinationIata,
      startDate: startDate,
      endDate: endDate,
      description: description,
      destinationName: destinationName,
      nbTravelers: nbTravelers,
      coverImageUrl: coverImageUrl,
      budgetTotal: budgetTotal,
      origin: origin,
    );
    if (result is Success) {
      await _invalidateListCaches();
    }
    return result;
  }

  @override
  Future<Result<Trip>> updateTrip(
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    final result = await _remote.updateTrip(tripId, updates);
    if (result is Success) {
      await _invalidateTripCaches(tripId);
    }
    return result;
  }

  @override
  Future<Result<Trip>> updateTripStatus(String tripId, String status) async {
    final result = await _remote.updateTripStatus(tripId, status);
    if (result is Success) {
      await _invalidateTripCaches(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteTrip(String tripId) async {
    final result = await _remote.deleteTrip(tripId);
    if (result is Success) {
      await _invalidateTripCaches(tripId);
    }
    return result;
  }

  // --------------- Helpers ---------------

  Future<Result<T>> _fromCache<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final cached = await _cache.get(_box, key);
    if (cached != null) {
      return Success(fromJson(cached));
    }
    return const Failure(NetworkError('No cached data available'));
  }

  Future<void> _invalidateListCaches() async {
    await _cache.delete(_box, 'grouped_trips');
    await _cache.delete(_box, 'all_trips');
  }

  Future<void> _invalidateTripCaches(String tripId) async {
    await _invalidateListCaches();
    await _cache.delete(_box, 'trip:$tripId');
    await _cache.delete(_box, 'trip_home:$tripId');
  }
}
