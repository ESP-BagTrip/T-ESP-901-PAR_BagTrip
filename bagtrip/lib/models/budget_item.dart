import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_item.freezed.dart';
part 'budget_item.g.dart';

@JsonEnum(alwaysCreate: true)
enum BudgetCategory {
  @JsonValue('FLIGHT')
  flight,
  @JsonValue('ACCOMMODATION')
  accommodation,
  @JsonValue('FOOD')
  food,
  @JsonValue('ACTIVITY')
  activity,
  @JsonValue('TRANSPORT')
  transport,
  @JsonValue('OTHER')
  other,
}

@freezed
abstract class BudgetItem with _$BudgetItem {
  const factory BudgetItem({
    required String id,
    required String tripId,
    required String label,
    required double amount,
    @JsonKey(unknownEnumValue: BudgetCategory.other)
    @Default(BudgetCategory.other)
    BudgetCategory category,
    DateTime? date,
    @Default(true) bool isPlanned,
    String? sourceType,
    String? sourceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BudgetItem;

  factory BudgetItem.fromJson(Map<String, dynamic> json) =>
      _$BudgetItemFromJson(json);
}

@freezed
abstract class BudgetSummary with _$BudgetSummary {
  const factory BudgetSummary({
    @JsonKey(name: 'totalBudget') @Default(0) double totalBudget,
    @JsonKey(name: 'totalSpent') @Default(0) double totalSpent,
    @Default(0) double remaining,
    @JsonKey(name: 'byCategory') @Default({}) Map<String, double> byCategory,
    @JsonKey(name: 'confirmedTotal') @Default(0) double confirmedTotal,
    @JsonKey(name: 'forecastedTotal') @Default(0) double forecastedTotal,
    @JsonKey(name: 'percentConsumed') double? percentConsumed,
    @JsonKey(name: 'alertLevel') String? alertLevel,
    @JsonKey(name: 'alertMessage') String? alertMessage,
    // Topic 06 (B9) — coarse-grained bucket the server emits for VIEWERs.
    // Owners / editors get `null` here (they have the raw figures);
    // viewers get one of `onTrack` / `tight` / `overBudget`.
    @JsonKey(name: 'budgetStatus') String? budgetStatus,
  }) = _BudgetSummary;

  factory BudgetSummary.fromJson(Map<String, dynamic> json) =>
      _$BudgetSummaryFromJson(json);
}
