import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';

abstract class TripRepository {
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
  });
  Future<Result<List<Trip>>> getTrips();
  Future<Result<TripGrouped>> getGroupedTrips();
  Future<Result<PaginatedResponse<Trip>>> getTripsPaginated({
    int page = 1,
    int limit = 20,
    String? status,
  });
  Future<Result<TripHome>> getTripHome(String tripId);
  Future<Result<Trip>> getTripById(String tripId);
  Future<Result<Trip>> updateTripStatus(String tripId, String status);
  Future<Result<Trip>> updateTrip(String tripId, Map<String, dynamic> updates);

  /// Toggle whether BagTrip tracks flights / accommodations for this trip.
  /// Pass `null` to keep the current value for either flag.
  Future<Result<Trip>> updateTripTracking(
    String tripId, {
    String? flightsTracking,
    String? accommodationsTracking,
  });
  Future<Result<void>> deleteTrip(String tripId);
}
