// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baggage_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BaggageItem _$BaggageItemFromJson(Map<String, dynamic> json) => _BaggageItem(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  name: json['name'] as String,
  quantity: (json['quantity'] as num?)?.toInt(),
  isPacked: json['isPacked'] as bool? ?? false,
  category: json['category'] as String?,
  notes: json['notes'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$BaggageItemToJson(_BaggageItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'name': instance.name,
      'quantity': instance.quantity,
      'isPacked': instance.isPacked,
      'category': instance.category,
      'notes': instance.notes,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
