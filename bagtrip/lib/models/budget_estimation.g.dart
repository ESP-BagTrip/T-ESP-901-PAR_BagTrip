// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_estimation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetEstimation _$BudgetEstimationFromJson(Map<String, dynamic> json) =>
    _BudgetEstimation(
      accommodationPerNight: (json['accommodationPerNight'] as num?)
          ?.toDouble(),
      mealsPerDayPerPerson: (json['mealsPerDayPerPerson'] as num?)?.toDouble(),
      localTransportPerDay: (json['localTransportPerDay'] as num?)?.toDouble(),
      activitiesTotal: (json['activitiesTotal'] as num?)?.toDouble(),
      totalMin: (json['totalMin'] as num?)?.toDouble(),
      totalMax: (json['totalMax'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      breakdownNotes: json['breakdownNotes'] as String?,
    );

Map<String, dynamic> _$BudgetEstimationToJson(_BudgetEstimation instance) =>
    <String, dynamic>{
      'accommodationPerNight': instance.accommodationPerNight,
      'mealsPerDayPerPerson': instance.mealsPerDayPerPerson,
      'localTransportPerDay': instance.localTransportPerDay,
      'activitiesTotal': instance.activitiesTotal,
      'totalMin': instance.totalMin,
      'totalMax': instance.totalMax,
      'currency': instance.currency,
      'breakdownNotes': instance.breakdownNotes,
    };
