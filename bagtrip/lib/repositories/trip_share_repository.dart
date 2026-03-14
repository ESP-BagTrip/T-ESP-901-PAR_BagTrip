import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip_share.dart';

abstract class TripShareRepository {
  Future<Result<TripShare>> createShare(String tripId, {required String email});
  Future<Result<List<TripShare>>> getSharesByTrip(String tripId);
  Future<Result<void>> deleteShare(String tripId, String shareId);
}
