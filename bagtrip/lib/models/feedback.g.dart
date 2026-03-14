// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripFeedback _$TripFeedbackFromJson(Map<String, dynamic> json) =>
    _TripFeedback(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      overallRating: (json['overallRating'] as num).toInt(),
      highlights: json['highlights'] as String?,
      lowlights: json['lowlights'] as String?,
      wouldRecommend: json['wouldRecommend'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TripFeedbackToJson(_TripFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'userId': instance.userId,
      'overallRating': instance.overallRating,
      'highlights': instance.highlights,
      'lowlights': instance.lowlights,
      'wouldRecommend': instance.wouldRecommend,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
