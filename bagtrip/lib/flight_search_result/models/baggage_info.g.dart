// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baggage_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BaggageInfo _$BaggageInfoFromJson(Map<String, dynamic> json) => _BaggageInfo(
  quantity: (json['quantity'] as num?)?.toInt(),
  weight: (json['weight'] as num?)?.toInt(),
  weightUnit: json['weightUnit'] as String?,
);

Map<String, dynamic> _$BaggageInfoToJson(_BaggageInfo instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'weight': instance.weight,
      'weightUnit': instance.weightUnit,
    };
