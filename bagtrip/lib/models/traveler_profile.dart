import 'package:freezed_annotation/freezed_annotation.dart';

part 'traveler_profile.freezed.dart';
part 'traveler_profile.g.dart';

@freezed
abstract class TravelerProfile with _$TravelerProfile {
  const factory TravelerProfile({
    required String id,
    @JsonKey(name: 'travelTypes') @Default([]) List<String> travelTypes,
    @JsonKey(name: 'travelStyle') String? travelStyle,
    String? budget,
    String? companions,
    @JsonKey(name: 'travelFrequency') String? travelFrequency,
    @JsonKey(name: 'medicalConstraints') String? medicalConstraints,
    @JsonKey(name: 'isCompleted') @Default(false) bool isCompleted,
    @JsonKey(name: 'createdAt') DateTime? createdAt,
    @JsonKey(name: 'updatedAt') DateTime? updatedAt,
  }) = _TravelerProfile;

  factory TravelerProfile.fromJson(Map<String, dynamic> json) =>
      _$TravelerProfileFromJson(json);
}

@freezed
abstract class ProfileCompletion with _$ProfileCompletion {
  const factory ProfileCompletion({
    @JsonKey(name: 'isCompleted') @Default(false) bool isCompleted,
    @JsonKey(name: 'missingFields') @Default([]) List<String> missingFields,
  }) = _ProfileCompletion;

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) =>
      _$ProfileCompletionFromJson(json);
}
