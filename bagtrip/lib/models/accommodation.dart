import 'package:freezed_annotation/freezed_annotation.dart';

part 'accommodation.freezed.dart';
part 'accommodation.g.dart';

@freezed
abstract class Accommodation with _$Accommodation {
  const factory Accommodation({
    required String id,
    required String tripId,
    required String name,
    String? address,
    DateTime? checkIn,
    DateTime? checkOut,
    double? pricePerNight,
    String? currency,
    String? bookingReference,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Accommodation;

  factory Accommodation.fromJson(Map<String, dynamic> json) =>
      _$AccommodationFromJson(json);
}
