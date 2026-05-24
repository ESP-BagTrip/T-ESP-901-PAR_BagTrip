import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_estimation.freezed.dart';
part 'budget_estimation.g.dart';

@freezed
abstract class BudgetEstimation with _$BudgetEstimation {
  const factory BudgetEstimation({
    @JsonKey(name: 'accommodationPerNight') double? accommodationPerNight,
    @JsonKey(name: 'mealsPerDayPerPerson') double? mealsPerDayPerPerson,
    @JsonKey(name: 'localTransportPerDay') double? localTransportPerDay,
    @JsonKey(name: 'activitiesTotal') double? activitiesTotal,
    @JsonKey(name: 'totalMin') double? totalMin,
    @JsonKey(name: 'totalMax') double? totalMax,
    @Default('EUR') String currency,
    @JsonKey(name: 'breakdownNotes') String? breakdownNotes,
  }) = _BudgetEstimation;

  factory BudgetEstimation.fromJson(Map<String, dynamic> json) =>
      _$BudgetEstimationFromJson(json);
}
