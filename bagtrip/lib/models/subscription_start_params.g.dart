// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_start_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionStartParams _$SubscriptionStartParamsFromJson(
  Map<String, dynamic> json,
) => _SubscriptionStartParams(
  subscriptionId: json['subscription_id'] as String,
  paymentIntentClientSecret: json['payment_intent_client_secret'] as String,
  ephemeralKey: json['ephemeral_key'] as String,
  customer: json['customer'] as String,
);

Map<String, dynamic> _$SubscriptionStartParamsToJson(
  _SubscriptionStartParams instance,
) => <String, dynamic>{
  'subscription_id': instance.subscriptionId,
  'payment_intent_client_secret': instance.paymentIntentClientSecret,
  'ephemeral_key': instance.ephemeralKey,
  'customer': instance.customer,
};
