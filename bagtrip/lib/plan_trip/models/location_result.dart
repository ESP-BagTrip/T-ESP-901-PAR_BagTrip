import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_result.freezed.dart';
part 'location_result.g.dart';

/// Typed wrapper around a location search result from the Amadeus API.
@freezed
abstract class LocationResult with _$LocationResult {
  const factory LocationResult({
    required String name,
    @JsonKey(name: 'iataCode') required String iataCode,
    @Default('') String city,
    @JsonKey(name: 'countryCode') @Default('') String countryCode,
    @JsonKey(name: 'countryName') @Default('') String countryName,
    @JsonKey(name: 'subType') @Default('') String subType,
  }) = _LocationResult;

  factory LocationResult.fromJson(Map<String, dynamic> json) =>
      _$LocationResultFromJson(json);
}
