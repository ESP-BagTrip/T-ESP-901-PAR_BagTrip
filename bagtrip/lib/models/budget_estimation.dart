import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_estimation.freezed.dart';
part 'budget_estimation.g.dart';

@freezed
abstract class BudgetEstimation with _$BudgetEstimation {
  const factory BudgetEstimation({
    double? accommodationPerNight,
    double? mealsPerDayPerPerson,
    double? localTransportPerDay,
    double? activitiesTotal,
    double? totalMin,
    double? totalMax,
    @Default('EUR') String currency,
    String? breakdownNotes,
  }) = _BudgetEstimation;

  factory BudgetEstimation.fromJson(Map<String, dynamic> json) =>
      _$BudgetEstimationFromJson(json);
}
