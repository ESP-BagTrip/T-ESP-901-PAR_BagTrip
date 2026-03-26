// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecentBooking _$RecentBookingFromJson(Map<String, dynamic> json) =>
    _RecentBooking(
      id: json['id'] as String,
      details: json['details'] as String,
      date: DateTime.parse(json['date'] as String),
      priceTotal: (json['priceTotal'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$RecentBookingToJson(_RecentBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'details': instance.details,
      'date': instance.date.toIso8601String(),
      'priceTotal': instance.priceTotal,
      'currency': instance.currency,
      'status': instance.status,
    };
