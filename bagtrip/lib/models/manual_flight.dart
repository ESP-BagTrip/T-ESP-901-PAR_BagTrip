import 'package:bagtrip/models/validation_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'manual_flight.freezed.dart';
part 'manual_flight.g.dart';

@freezed
abstract class ManualFlight with _$ManualFlight {
  const factory ManualFlight({
    required String id,
    required String tripId,
    required String flightNumber,
    String? airline,
    String? departureAirport,
    String? arrivalAirport,
    DateTime? departureDate,
    DateTime? arrivalDate,
    double? price,
    String? currency,
    String? notes,
    @Default('MAIN') String flightType,
    @JsonKey(unknownEnumValue: ValidationStatus.manual)
    @Default(ValidationStatus.manual)
    ValidationStatus validationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ManualFlight;

  factory ManualFlight.fromJson(Map<String, dynamic> json) =>
      _$ManualFlightFromJson(json);
}
