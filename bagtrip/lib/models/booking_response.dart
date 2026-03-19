import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_response.freezed.dart';
part 'booking_response.g.dart';

/// Response model for a single booking from GET /v1/booking/list.
@freezed
abstract class BookingResponse with _$BookingResponse {
  const factory BookingResponse({
    required String id,
    @JsonKey(name: 'amadeusOrderId') required String amadeusOrderId,
    required String status,
    @JsonKey(name: 'priceTotal') required double priceTotal,
    required String currency,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
  }) = _BookingResponse;

  factory BookingResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingResponseFromJson(json);
}
