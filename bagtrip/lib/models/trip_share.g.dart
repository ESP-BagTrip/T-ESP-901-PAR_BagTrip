// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripShare _$TripShareFromJson(Map<String, dynamic> json) => _TripShare(
  id: json['id'] as String,
  tripId: json['trip_id'] as String,
  userId: json['user_id'] as String?,
  role: json['role'] as String? ?? 'VIEWER',
  invitedAt: json['invited_at'] == null
      ? null
      : DateTime.parse(json['invited_at'] as String),
  userEmail: json['user_email'] as String,
  userFullName: json['user_full_name'] as String?,
  status: json['status'] as String? ?? 'active',
  inviteToken: json['invite_token'] as String?,
);

Map<String, dynamic> _$TripShareToJson(_TripShare instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'user_id': instance.userId,
      'role': instance.role,
      'invited_at': instance.invitedAt?.toIso8601String(),
      'user_email': instance.userEmail,
      'user_full_name': instance.userFullName,
      'status': instance.status,
      'invite_token': instance.inviteToken,
    };
