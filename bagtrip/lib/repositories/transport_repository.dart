import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/models/manual_flight.dart';

/// Response from persisted flight search endpoint.
class PersistedFlightSearchResult {
  final String searchId;
  final List<dynamic> amadeusData;
  final Map<String, dynamic>? dictionaries;

  PersistedFlightSearchResult({
    required this.searchId,
    required this.amadeusData,
    this.dictionaries,
  });
}

abstract class TransportRepository {
  Future<Result<ManualFlight>> createManualFlight(
    String tripId,
    Map<String, dynamic> data,
  );
  Future<Result<List<ManualFlight>>> getManualFlights(String tripId);
  Future<Result<void>> deleteManualFlight(String tripId, String flightId);
  Future<Result<ManualFlight>> updateManualFlight(
    String tripId,
    String flightId,
    Map<String, dynamic> data,
  );
  Future<Result<FlightInfo>> lookupFlight(String flightNumber);
  Future<Result<List<PersistedFlightSearchResult>>> searchMultiDestFlights({
    required String tripId,
    required List<Map<String, dynamic>> segments,
    required int adults,
    int? children,
    int? infants,
    String? travelClass,
    String? currency,
  });
  Future<Result<PersistedFlightSearchResult>> searchFlightsPersisted({
    required String tripId,
    required String originIata,
    required String destinationIata,
    required String departureDate,
    String? returnDate,
    required int adults,
    int? children,
    int? infants,
    String? travelClass,
    String? currency,
  });
}
