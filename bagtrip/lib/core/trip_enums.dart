/// String constants mirroring the backend enums for flight/hotel tracking and
/// flight type. Stored as raw strings in the Trip/ManualFlight models to keep
/// the JSON wire format simple (no JsonConverter needed).
///
/// For per-item validation status, see [ValidationStatus] in
/// `models/validation_status.dart` — that one is a real Dart enum because
/// it's used heavily in UI comparisons.
class TrackingStatus {
  const TrackingStatus._();

  static const String tracked = 'TRACKED';
  static const String skipped = 'SKIPPED';
}

class FlightType {
  const FlightType._();

  static const String main = 'MAIN';
  static const String returnType = 'RETURN';
  static const String internal = 'INTERNAL';
  static const String aiSuggested = 'AI_SUGGESTED';
}
