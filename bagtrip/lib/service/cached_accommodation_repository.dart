import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';

class CachedAccommodationRepository implements AccommodationRepository {
  final AccommodationRepository _remote;
  final CacheService _cache;
  final ConnectivityService _connectivity;
  final OfflineWriteQueue? _queue;

  static const _box = 'accommodation_cache';

  CachedAccommodationRepository({
    required AccommodationRepository remote,
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
    q.registerHandler('accommodation:createAccommodation', (args) async {
      final result = await _remote.createAccommodation(
        args['tripId'] as String,
        name: args['name'] as String,
        address: args['address'] as String?,
        checkIn: _parseDate(args['checkIn']),
        checkOut: _parseDate(args['checkOut']),
        pricePerNight: (args['pricePerNight'] as num?)?.toDouble(),
        currency: args['currency'] as String?,
        bookingReference: args['bookingReference'] as String?,
        notes: args['notes'] as String?,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('accommodation:updateAccommodation', (args) async {
      final result = await _remote.updateAccommodation(
        args['tripId'] as String,
        args['accommodationId'] as String,
        Map<String, dynamic>.from(args['updates'] as Map),
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
    q.registerHandler('accommodation:deleteAccommodation', (args) async {
      final result = await _remote.deleteAccommodation(
        args['tripId'] as String,
        args['accommodationId'] as String,
      );
      if (result is Success) await _invalidate(args['tripId'] as String);
      return result is Success;
    });
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw as String);
  }

  // --------------- READ methods ---------------

  @override
  Future<Result<List<Accommodation>>> getByTrip(String tripId) async {
    final key = 'accommodations:$tripId';
    if (_connectivity.isOnline) {
      final result = await _remote.getByTrip(tripId);
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
          .map(
            (e) => Accommodation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return Success(items);
    }
    return const Failure(UnknownError('No cached data available'));
  }

  // --------------- WRITE methods ---------------

  @override
  Future<Result<Accommodation>> createAccommodation(
    String tripId, {
    required String name,
    String? address,
    DateTime? checkIn,
    DateTime? checkOut,
    double? pricePerNight,
    String? currency,
    String? bookingReference,
    String? notes,
  }) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'accommodation',
          method: 'createAccommodation',
          arguments: {
            'tripId': tripId,
            'name': name,
            'address': address,
            'checkIn': checkIn?.toIso8601String(),
            'checkOut': checkOut?.toIso8601String(),
            'pricePerNight': pricePerNight,
            'currency': currency,
            'bookingReference': bookingReference,
            'notes': notes,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.createAccommodation(
      tripId,
      name: name,
      address: address,
      checkIn: checkIn,
      checkOut: checkOut,
      pricePerNight: pricePerNight,
      currency: currency,
      bookingReference: bookingReference,
      notes: notes,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<Accommodation>> updateAccommodation(
    String tripId,
    String accommodationId,
    Map<String, dynamic> updates,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'accommodation',
          method: 'updateAccommodation',
          arguments: {
            'tripId': tripId,
            'accommodationId': accommodationId,
            'updates': updates,
          },
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.updateAccommodation(
      tripId,
      accommodationId,
      updates,
    );
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  @override
  Future<Result<void>> deleteAccommodation(
    String tripId,
    String accommodationId,
  ) async {
    if (!_connectivity.isOnline && _queue != null) {
      await _queue.enqueue(
        PendingWriteOperation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          repository: 'accommodation',
          method: 'deleteAccommodation',
          arguments: {'tripId': tripId, 'accommodationId': accommodationId},
          createdAt: DateTime.now(),
        ),
      );
      return const Failure(NetworkError('Operation queued for sync'));
    }
    final result = await _remote.deleteAccommodation(tripId, accommodationId);
    if (result is Success) {
      await _invalidate(tripId);
    }
    return result;
  }

  // --------------- Pass-through methods ---------------

  @override
  Future<Result<List<Map<String, dynamic>>>> suggestAccommodations(
    String tripId, {
    String? constraints,
  }) async {
    return _remote.suggestAccommodations(tripId, constraints: constraints);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> searchHotelsByCity(
    String cityCode, {
    String? checkIn,
    String? checkOut,
    int? adults,
    String? ratings,
  }) async {
    return _remote.searchHotelsByCity(
      cityCode,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      ratings: ratings,
    );
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> searchHotelOffers(
    String hotelIds, {
    String? checkIn,
    String? checkOut,
    int? adults,
    String? currency,
  }) async {
    return _remote.searchHotelOffers(
      hotelIds,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      currency: currency,
    );
  }

  // --------------- Helpers ---------------

  Future<void> _invalidate(String tripId) async {
    await _cache.delete(_box, 'accommodations:$tripId');
  }
}
