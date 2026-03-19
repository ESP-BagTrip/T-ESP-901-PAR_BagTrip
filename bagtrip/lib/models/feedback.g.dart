// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripFeedback _$TripFeedbackFromJson(Map<String, dynamic> json) =>
    _TripFeedback(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      userId: json['user_id'] as String,
      overallRating: (json['overall_rating'] as num).toInt(),
      highlights: json['highlights'] as String?,
      lowlights: json['lowlights'] as String?,
      wouldRecommend: json['would_recommend'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TripFeedbackToJson(_TripFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trip_id': instance.tripId,
      'user_id': instance.userId,
      'overall_rating': instance.overallRating,
      'highlights': instance.highlights,
      'lowlights': instance.lowlights,
      'would_recommend': instance.wouldRecommend,
      'created_at': instance.createdAt?.toIso8601String(),
    };
