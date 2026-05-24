// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_start_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionStartParams _$SubscriptionStartParamsFromJson(
  Map<String, dynamic> json,
) => _SubscriptionStartParams(
  customer: json['customer'] as String,
  ephemeralKey: json['ephemeral_key'] as String,
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String,
);

Map<String, dynamic> _$SubscriptionStartParamsToJson(
  _SubscriptionStartParams instance,
) => <String, dynamic>{
  'customer': instance.customer,
  'ephemeral_key': instance.ephemeralKey,
  'amount': instance.amount,
  'currency': instance.currency,
};
