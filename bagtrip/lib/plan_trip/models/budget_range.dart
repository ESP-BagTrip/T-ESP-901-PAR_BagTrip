import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_range.freezed.dart';
part 'budget_range.g.dart';

/// A min/max budget range in EUR.
@freezed
abstract class BudgetRange with _$BudgetRange {
  const factory BudgetRange({required double min, required double max}) =
      _BudgetRange;

  factory BudgetRange.fromJson(Map<String, dynamic> json) =>
      _$BudgetRangeFromJson(json);
}
