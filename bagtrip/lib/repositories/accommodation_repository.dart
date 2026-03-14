import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';

abstract class AccommodationRepository {
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
  });
  Future<Result<List<Accommodation>>> getByTrip(String tripId);
  Future<Result<Accommodation>> updateAccommodation(
    String tripId,
    String accommodationId,
    Map<String, dynamic> updates,
  );
  Future<Result<void>> deleteAccommodation(
    String tripId,
    String accommodationId,
  );
}
