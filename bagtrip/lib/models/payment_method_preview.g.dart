// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentMethodPreview _$PaymentMethodPreviewFromJson(
  Map<String, dynamic> json,
) => _PaymentMethodPreview(
  brand: json['brand'] as String?,
  last4: json['last4'] as String?,
  expMonth: (json['exp_month'] as num?)?.toInt(),
  expYear: (json['exp_year'] as num?)?.toInt(),
);

Map<String, dynamic> _$PaymentMethodPreviewToJson(
  _PaymentMethodPreview instance,
) => <String, dynamic>{
  'brand': instance.brand,
  'last4': instance.last4,
  'exp_month': instance.expMonth,
  'exp_year': instance.expYear,
};
