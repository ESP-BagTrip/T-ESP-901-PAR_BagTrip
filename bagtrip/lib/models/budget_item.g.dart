// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetItem _$BudgetItemFromJson(Map<String, dynamic> json) => _BudgetItem(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  label: json['label'] as String,
  amount: (json['amount'] as num).toDouble(),
  category:
      $enumDecodeNullable(
        _$BudgetCategoryEnumMap,
        json['category'],
        unknownValue: BudgetCategory.other,
      ) ??
      BudgetCategory.other,
  date: json['date'] == null ? null : DateTime.parse(json['date'] as String),
  isPlanned: json['is_planned'] as bool? ?? true,
  sourceType: json['source_type'] as String?,
  sourceId: json['source_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BudgetItemToJson(_BudgetItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'label': instance.label,
      'amount': instance.amount,
      'category': _$BudgetCategoryEnumMap[instance.category]!,
      'date': instance.date?.toIso8601String(),
      'is_planned': instance.isPlanned,
      'source_type': instance.sourceType,
      'source_id': instance.sourceId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
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
      budgetStatus: json['budgetStatus'] as String?,
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
      'budgetStatus': instance.budgetStatus,
    };
