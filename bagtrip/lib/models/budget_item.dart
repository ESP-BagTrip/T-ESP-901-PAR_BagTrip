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
    @Default(BudgetCategory.other) BudgetCategory category,
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
    @Default(0) double totalBudget,
    @Default(0) double totalSpent,
    @Default(0) double remaining,
    @Default({}) Map<String, double> byCategory,
    @Default(0) double confirmedTotal,
    @Default(0) double forecastedTotal,
    double? percentConsumed,
    String? alertLevel,
    String? alertMessage,
  }) = _BudgetSummary;

  factory BudgetSummary.fromJson(Map<String, dynamic> json) =>
      _$BudgetSummaryFromJson(json);
}
