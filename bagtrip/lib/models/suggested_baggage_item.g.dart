// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggested_baggage_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SuggestedBaggageItem _$SuggestedBaggageItemFromJson(
  Map<String, dynamic> json,
) => _SuggestedBaggageItem(
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  category: json['category'] as String? ?? 'Autre',
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$SuggestedBaggageItemToJson(
  _SuggestedBaggageItem instance,
) => <String, dynamic>{
  'name': instance.name,
  'quantity': instance.quantity,
  'category': instance.category,
  'reason': instance.reason,
};
