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
    required String tripId,
    required String title,
    String? description,
    required DateTime date,
    String? startTime,
    String? endTime,
    String? location,
    @Default(ActivityCategory.other) ActivityCategory category,
    double? estimatedCost,
    @Default(false) bool isBooked,
    @Default(ValidationStatus.manual) ValidationStatus validationStatus,
    int? suggestedDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}
