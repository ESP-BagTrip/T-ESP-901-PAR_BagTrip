// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invoice _$InvoiceFromJson(Map<String, dynamic> json) => _Invoice(
  id: json['id'] as String,
  number: json['number'] as String?,
  status: json['status'] as String?,
  amountPaid: (json['amount_paid'] as num?)?.toInt(),
  currency: json['currency'] as String?,
  created: json['created'] == null
      ? null
      : DateTime.parse(json['created'] as String),
  hostedInvoiceUrl: json['hosted_invoice_url'] as String?,
  invoicePdf: json['invoice_pdf'] as String?,
);

Map<String, dynamic> _$InvoiceToJson(_Invoice instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'status': instance.status,
  'amount_paid': instance.amountPaid,
  'currency': instance.currency,
  'created': instance.created?.toIso8601String(),
  'hosted_invoice_url': instance.hostedInvoiceUrl,
  'invoice_pdf': instance.invoicePdf,
};
