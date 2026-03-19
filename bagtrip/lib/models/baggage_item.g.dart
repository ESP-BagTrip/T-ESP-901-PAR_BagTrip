// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baggage_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BaggageItem _$BaggageItemFromJson(Map<String, dynamic> json) => _BaggageItem(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt(),
  isPacked: json['is_packed'] as bool? ?? false,
  category: json['category'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BaggageItemToJson(_BaggageItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'name': instance.name,
      'quantity': instance.quantity,
      'is_packed': instance.isPacked,
      'category': instance.category,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
