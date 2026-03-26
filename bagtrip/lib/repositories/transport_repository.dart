import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/models/manual_flight.dart';

abstract class TransportRepository {
  Future<Result<ManualFlight>> createManualFlight(
    String tripId,
    Map<String, dynamic> data,
  );
  Future<Result<List<ManualFlight>>> getManualFlights(String tripId);
  Future<Result<void>> deleteManualFlight(String tripId, String flightId);
  Future<Result<FlightInfo>> lookupFlight(String flightNumber);
}
