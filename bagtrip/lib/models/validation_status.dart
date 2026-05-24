import 'package:freezed_annotation/freezed_annotation.dart';

/// Shared status enum for every user-validated domain (activities, flights,
/// accommodations). Mirrors the backend `ValidationStatus` StrEnum.
///
/// - [suggested] — pre-populated by the LLM; the user hasn't decided yet.
/// - [validated] — the user has explicitly confirmed the proposal.
/// - [manual] — the user added or edited the item themselves.
@JsonEnum(alwaysCreate: true)
enum ValidationStatus {
  @JsonValue('SUGGESTED')
  suggested,
  @JsonValue('VALIDATED')
  validated,
  @JsonValue('MANUAL')
  manual,
}

extension ValidationStatusX on ValidationStatus {
  /// Whether the user has decided on this item (validated it or added it).
  /// Used by the trip completion score and the validation board.
  bool get isDone =>
      this == ValidationStatus.validated || this == ValidationStatus.manual;
}
