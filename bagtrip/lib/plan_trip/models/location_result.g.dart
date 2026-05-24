// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LocationResult _$LocationResultFromJson(Map<String, dynamic> json) =>
    _LocationResult(
      name: json['name'] as String,
      iataCode: json['iataCode'] as String,
      city: json['city'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      countryName: json['countryName'] as String? ?? '',
      subType: json['subType'] as String? ?? '',
    );

Map<String, dynamic> _$LocationResultToJson(_LocationResult instance) =>
    <String, dynamic>{
      'name': instance.name,
      'iataCode': instance.iataCode,
      'city': instance.city,
      'countryCode': instance.countryCode,
      'countryName': instance.countryName,
      'subType': instance.subType,
    };
