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
  Future<Result<List<Map<String, dynamic>>>> suggestAccommodations(
    String tripId, {
    String? constraints,
  });
  Future<Result<List<Map<String, dynamic>>>> searchHotelsByCity(
    String cityCode, {
    String? checkIn,
    String? checkOut,
    int? adults,
    String? ratings,
  });
  Future<Result<List<Map<String, dynamic>>>> searchHotelOffers(
    String hotelIds, {
    String? checkIn,
    String? checkOut,
    int? adults,
    String? currency,
  });
}
