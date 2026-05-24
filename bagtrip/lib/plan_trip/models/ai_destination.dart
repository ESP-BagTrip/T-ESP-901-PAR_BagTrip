import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:bagtrip/plan_trip/models/budget_range.dart';

part 'ai_destination.freezed.dart';
part 'ai_destination.g.dart';

/// An AI-suggested destination with context (weather, activities, budget).
@freezed
abstract class AiDestination with _$AiDestination {
  const factory AiDestination({
    required String city,
    required String country,
    String? iata,
    double? lat,
    double? lon,
    @JsonKey(name: 'match_reason') String? matchReason,
    @JsonKey(name: 'weather_summary') String? weatherSummary,
    @JsonKey(name: 'image_url') String? imageUrl,
    @Default([]) List<String> topActivities,
    BudgetRange? estimatedBudgetRange,
  }) = _AiDestination;

  factory AiDestination.fromJson(Map<String, dynamic> json) =>
      _$AiDestinationFromJson(json);
}
