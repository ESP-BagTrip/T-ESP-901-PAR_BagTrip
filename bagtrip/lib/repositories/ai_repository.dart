import 'package:bagtrip/core/result.dart';

/// Contract the wizard relies on to talk to the AI backend.
///
/// The backend SSE pipeline persists the trip server-side at the end of
/// a successful run and ships a ``tripId`` in the ``complete`` event —
/// there is no longer a follow-up ``/accept`` round-trip. The wizard
/// just navigates to the trip detail with that id.
abstract class AiRepository {
  /// Fast destination ideas — wizard step "Inspire-me".
  ///
  /// Drains the ``destinations_only`` SSE flow and returns the first
  /// shipped destinations payload (or an empty list when the backend
  /// signalled an error / had no live inventory).
  ///
  /// ``originCity`` is REQUIRED for the W1 orchestrator: the resolver
  /// needs an origin IATA before it can hit Amadeus inspire. An empty
  /// origin yields ``error: ORIGIN_UNRESOLVED`` — the wizard must
  /// always thread ``state.originCity``.
  Future<Result<List<Map<String, dynamic>>>> getInspiration({
    required String originCity,
    String? travelTypes,
    String? budgetRange,
    int? durationDays,
    String? companions,
    String? season,
    String? constraints,
    String? departureDate,
    String? returnDate,
    int? nbTravelers,
    String? locale,
  });

  /// Premium-gated next-trip suggestion (W3).
  Future<Result<Map<String, dynamic>>> getPostTripSuggestion();

  /// Multi-agent SSE pipeline. Emits ``{event, data}`` maps.
  ///
  /// Modes:
  /// - ``full`` (default) — destination → activities + accommodation +
  ///   transport + baggage → budget → ``complete`` carries ``tripId``.
  /// - ``destinations_only`` — fast path that only emits the
  ///   destinations payload before ``complete``.
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
