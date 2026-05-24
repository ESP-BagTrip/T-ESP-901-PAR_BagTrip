// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method_setup_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentMethodSetupParams _$PaymentMethodSetupParamsFromJson(
  Map<String, dynamic> json,
) => _PaymentMethodSetupParams(
  setupIntentClientSecret: json['setup_intent_client_secret'] as String,
  ephemeralKey: json['ephemeral_key'] as String,
  customer: json['customer'] as String,
);

Map<String, dynamic> _$PaymentMethodSetupParamsToJson(
  _PaymentMethodSetupParams instance,
) => <String, dynamic>{
  'setup_intent_client_secret': instance.setupIntentClientSecret,
  'ephemeral_key': instance.ephemeralKey,
  'customer': instance.customer,
};
