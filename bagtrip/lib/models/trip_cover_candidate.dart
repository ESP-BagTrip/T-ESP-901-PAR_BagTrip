// SMP-330 — one alternative cover image the backend surfaced for a
// destination, used to drive the "Change cover" bottom sheet.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_cover_candidate.freezed.dart';
part 'trip_cover_candidate.g.dart';

@freezed
abstract class TripCoverCandidate with _$TripCoverCandidate {
  const factory TripCoverCandidate({
    required String url,
    required String source,
    String? title,
    String? attribution,
  }) = _TripCoverCandidate;

  factory TripCoverCandidate.fromJson(Map<String, dynamic> json) =>
      _$TripCoverCandidateFromJson(json);
}
