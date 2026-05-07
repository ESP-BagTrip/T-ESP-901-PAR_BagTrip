import 'package:bagtrip/core/result.dart';

abstract class AiRepository {
  Future<Result<List<Map<String, dynamic>>>> getInspiration({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
    String? constraints,
    String? locale,
  });
  // SMP-324 — ``acceptInspiration`` is gone. The SSE pipeline persists
  // a DRAFT trip itself and ships its ``tripId`` in the ``complete``
  // event; confirming is just ``TripRepository.updateTripStatus(id,
  // "PLANNED")``.
  Future<Result<Map<String, dynamic>>> getPostTripSuggestion();

  /// Stream trip planning events via SSE from the multi-agent pipeline.
  /// Each emitted map has: {"event": "...", "data": {...}}
  /// [mode] can be 'full' (default) or 'destinations_only'.
  Stream<Map<String, dynamic>> planTripStream({
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? constraints,
    String? departureDate,
    String? returnDate,
    String? originCity,
    String? destinationCity,
    String? destinationIata,
    String? mode,
    String? locale,
  });
}
