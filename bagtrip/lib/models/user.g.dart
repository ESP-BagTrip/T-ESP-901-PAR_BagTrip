// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String?,
  phone: json['phone'] as String?,
  stripeCustomerId: json['stripeCustomerId'] as String?,
  isProfileCompleted: json['isProfileCompleted'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  plan: json['plan'] as String? ?? 'FREE',
  aiGenerationsRemaining: (json['aiGenerationsRemaining'] as num?)?.toInt(),
  planExpiresAt: json['planExpiresAt'] == null
      ? null
      : DateTime.parse(json['planExpiresAt'] as String),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'stripeCustomerId': instance.stripeCustomerId,
  'isProfileCompleted': instance.isProfileCompleted,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'plan': instance.plan,
  'aiGenerationsRemaining': instance.aiGenerationsRemaining,
  'planExpiresAt': instance.planExpiresAt?.toIso8601String(),
};
