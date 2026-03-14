import 'package:freezed_annotation/freezed_annotation.dart';

part 'traveler_profile.freezed.dart';
part 'traveler_profile.g.dart';

@freezed
abstract class TravelerProfile with _$TravelerProfile {
  const factory TravelerProfile({
    required String id,
    @Default([]) List<String> travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TravelerProfile;

  factory TravelerProfile.fromJson(Map<String, dynamic> json) =>
      _$TravelerProfileFromJson(json);
}

@freezed
abstract class ProfileCompletion with _$ProfileCompletion {
  const factory ProfileCompletion({
    @Default(false) bool isCompleted,
    @Default([]) List<String> missingFields,
  }) = _ProfileCompletion;

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) =>
      _$ProfileCompletionFromJson(json);
}
