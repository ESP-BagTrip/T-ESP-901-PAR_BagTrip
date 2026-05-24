// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingResponse _$BookingResponseFromJson(Map<String, dynamic> json) =>
    _BookingResponse(
      id: json['id'] as String,
      amadeusOrderId: json['amadeusOrderId'] as String,
      status: json['status'] as String,
      priceTotal: (json['priceTotal'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingResponseToJson(_BookingResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amadeusOrderId': instance.amadeusOrderId,
      'status': instance.status,
      'priceTotal': instance.priceTotal,
      'currency': instance.currency,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
