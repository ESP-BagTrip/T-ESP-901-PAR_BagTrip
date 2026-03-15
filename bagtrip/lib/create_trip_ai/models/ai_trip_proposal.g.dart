// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_trip_proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiTripProposal _$AiTripProposalFromJson(Map<String, dynamic> json) =>
    _AiTripProposal(
      id: json['id'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      destinationCountry: json['destinationCountry'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      priceEur: (json['budgetEur'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      activities:
          (json['activities'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      matchReason: json['matchReason'] as String?,
    );

Map<String, dynamic> _$AiTripProposalToJson(_AiTripProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'destination': instance.destination,
      'destinationCountry': instance.destinationCountry,
      'durationDays': instance.durationDays,
      'budgetEur': instance.priceEur,
      'description': instance.description,
      'activities': instance.activities,
      'matchReason': instance.matchReason,
    };
