// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_authorize_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentAuthorizeResponse _$PaymentAuthorizeResponseFromJson(
  Map<String, dynamic> json,
) => _PaymentAuthorizeResponse(
  stripePaymentIntentId: json['stripePaymentIntentId'] as String,
  clientSecret: json['clientSecret'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$PaymentAuthorizeResponseToJson(
  _PaymentAuthorizeResponse instance,
) => <String, dynamic>{
  'stripePaymentIntentId': instance.stripePaymentIntentId,
  'clientSecret': instance.clientSecret,
  'status': instance.status,
};
