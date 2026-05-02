// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetBreakdown _$BudgetBreakdownFromJson(Map<String, dynamic> json) =>
    _BudgetBreakdown(
      flight: (json['flight'] as num?)?.toDouble() ?? 0.0,
      accommodation: (json['accommodation'] as num?)?.toDouble() ?? 0.0,
      food: (json['food'] as num?)?.toDouble() ?? 0.0,
      transport: (json['transport'] as num?)?.toDouble() ?? 0.0,
      activity: (json['activity'] as num?)?.toDouble() ?? 0.0,
      other: (json['other'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$BudgetBreakdownToJson(_BudgetBreakdown instance) =>
    <String, dynamic>{
      'flight': instance.flight,
      'accommodation': instance.accommodation,
      'food': instance.food,
      'transport': instance.transport,
      'activity': instance.activity,
      'other': instance.other,
    };
