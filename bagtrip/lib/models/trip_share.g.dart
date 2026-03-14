// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripShare _$TripShareFromJson(Map<String, dynamic> json) => _TripShare(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  userId: json['userId'] as String,
  role: json['role'] as String? ?? 'VIEWER',
  invitedAt: json['invitedAt'] == null
      ? null
      : DateTime.parse(json['invitedAt'] as String),
  userEmail: json['userEmail'] as String,
  userFullName: json['userFullName'] as String?,
);

Map<String, dynamic> _$TripShareToJson(_TripShare instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'role': instance.role,
      'invitedAt': instance.invitedAt?.toIso8601String(),
      'userEmail': instance.userEmail,
      'userFullName': instance.userFullName,
    };
