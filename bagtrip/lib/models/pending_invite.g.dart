// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingInvite _$PendingInviteFromJson(Map<String, dynamic> json) =>
    _PendingInvite(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'VIEWER',
      token: json['token'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$PendingInviteToJson(_PendingInvite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'email': instance.email,
      'role': instance.role,
      'token': instance.token,
      'created_at': instance.createdAt?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
    };
