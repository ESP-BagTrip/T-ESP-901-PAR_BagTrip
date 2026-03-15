// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetItem _$BudgetItemFromJson(Map<String, dynamic> json) => _BudgetItem(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  label: json['label'] as String,
  amount: (json['amount'] as num).toDouble(),
  category:
      $enumDecodeNullable(_$BudgetCategoryEnumMap, json['category']) ??
      BudgetCategory.other,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  isPlanned: json['isPlanned'] as bool? ?? true,
  sourceType: json['sourceType'] as String?,
  sourceId: json['sourceId'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$BudgetItemToJson(_BudgetItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'label': instance.label,
      'amount': instance.amount,
      'category': _$BudgetCategoryEnumMap[instance.category]!,
      'date': instance.date?.toIso8601String(),
      'isPlanned': instance.isPlanned,
      'sourceType': instance.sourceType,
      'sourceId': instance.sourceId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$BudgetCategoryEnumMap = {
  BudgetCategory.flight: 'FLIGHT',
  BudgetCategory.accommodation: 'ACCOMMODATION',
  BudgetCategory.food: 'FOOD',
  BudgetCategory.activity: 'ACTIVITY',
  BudgetCategory.transport: 'TRANSPORT',
  BudgetCategory.other: 'OTHER',
};

_BudgetSummary _$BudgetSummaryFromJson(Map<String, dynamic> json) =>
    _BudgetSummary(
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
      byCategory:
          (json['byCategory'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      confirmedTotal: (json['confirmedTotal'] as num?)?.toDouble() ?? 0,
      forecastedTotal: (json['forecastedTotal'] as num?)?.toDouble() ?? 0,
      percentConsumed: (json['percentConsumed'] as num?)?.toDouble(),
      alertLevel: json['alertLevel'] as String?,
      alertMessage: json['alertMessage'] as String?,
    );

Map<String, dynamic> _$BudgetSummaryToJson(_BudgetSummary instance) =>
    <String, dynamic>{
      'totalBudget': instance.totalBudget,
      'totalSpent': instance.totalSpent,
      'remaining': instance.remaining,
      'byCategory': instance.byCategory,
      'confirmedTotal': instance.confirmedTotal,
      'forecastedTotal': instance.forecastedTotal,
      'percentConsumed': instance.percentConsumed,
      'alertLevel': instance.alertLevel,
      'alertMessage': instance.alertMessage,
    };
