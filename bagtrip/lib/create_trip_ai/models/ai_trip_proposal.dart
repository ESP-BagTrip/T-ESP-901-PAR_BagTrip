import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_trip_proposal.freezed.dart';
part 'ai_trip_proposal.g.dart';

/// Model for an AI-generated trip proposal (card on results page).
@freezed
abstract class AiTripProposal with _$AiTripProposal {
  const factory AiTripProposal({
    @Default('') String id,
    @Default('') String destination,
    @Default('') String destinationCountry,
    @Default(0) int durationDays,
    @JsonKey(name: 'budgetEur') @Default(0) int priceEur,
    @Default('') String description,
    @Default([]) List<Map<String, dynamic>> activities,
  }) = _AiTripProposal;

  factory AiTripProposal.fromJson(Map<String, dynamic> json) =>
      _$AiTripProposalFromJson(json);

  /// Parse from JSON with an external id parameter.
  static AiTripProposal fromJsonWithId(
    Map<String, dynamic> json, {
    String? id,
  }) {
    final proposal = AiTripProposal.fromJson(json);
    return proposal.copyWith(id: id ?? '');
  }
}
