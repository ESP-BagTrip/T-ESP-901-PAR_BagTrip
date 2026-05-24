// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentCard _$PaymentCardFromJson(Map<String, dynamic> json) => _PaymentCard(
  id: json['id'] as String,
  lastFourDigits: json['lastFourDigits'] as String,
  expiryDate: json['expiryDate'] as String,
  isDefault: json['isDefault'] as bool,
);

Map<String, dynamic> _$PaymentCardToJson(_PaymentCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lastFourDigits': instance.lastFourDigits,
      'expiryDate': instance.expiryDate,
      'isDefault': instance.isDefault,
    };
