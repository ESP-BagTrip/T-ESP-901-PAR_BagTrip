import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';
part 'activity.g.dart';

@JsonEnum(alwaysCreate: true)
enum ActivityCategory {
  @JsonValue('VISIT')
  visit,
  @JsonValue('RESTAURANT')
  restaurant,
  @JsonValue('TRANSPORT')
  transport,
  @JsonValue('LEISURE')
  leisure,
  @JsonValue('CULTURE')
  culture,
  @JsonValue('NATURE')
  nature,
  @JsonValue('OTHER')
  other,
}

@JsonEnum(alwaysCreate: true)
enum ValidationStatus {
  @JsonValue('SUGGESTED')
  suggested,
  @JsonValue('VALIDATED')
  validated,
  @JsonValue('MANUAL')
  manual,
}

@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    @JsonKey(name: 'trip_id') required String tripId,
    required String title,
    String? description,
    required DateTime date,
    @JsonKey(name: 'start_time') String? startTime,
    @JsonKey(name: 'end_time') String? endTime,
    String? location,
    @JsonKey(unknownEnumValue: ActivityCategory.other)
    @Default(ActivityCategory.other)
    ActivityCategory category,
    @JsonKey(name: 'estimated_cost') double? estimatedCost,
    @JsonKey(name: 'is_booked') @Default(false) bool isBooked,
    @JsonKey(name: 'validation_status')
    @Default(ValidationStatus.manual)
    ValidationStatus validationStatus,
    int? suggestedDay,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
