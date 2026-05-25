// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_cover_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TripCoverCandidate _$TripCoverCandidateFromJson(Map<String, dynamic> json) =>
    _TripCoverCandidate(
      url: json['url'] as String,
      source: json['source'] as String,
      title: json['title'] as String?,
      attribution: json['attribution'] as String?,
    );

Map<String, dynamic> _$TripCoverCandidateToJson(_TripCoverCandidate instance) =>
    <String, dynamic>{
      'url': instance.url,
      'source': instance.source,
      'title': instance.title,
      'attribution': instance.attribution,
    };
