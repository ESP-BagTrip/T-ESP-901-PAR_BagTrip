part of 'transport_bloc.dart';

abstract class TransportEvent {}

class LoadTransports extends TransportEvent {
  final String tripId;
  LoadTransports({required this.tripId});
}

class CreateManualFlight extends TransportEvent {
  final String tripId;
  final Map<String, dynamic> data;
  CreateManualFlight({required this.tripId, required this.data});
}

class DeleteManualFlight extends TransportEvent {
  final String tripId;
  final String flightId;
  DeleteManualFlight({required this.tripId, required this.flightId});
}

class LookupFlightInfo extends TransportEvent {
  final String flightNumber;
  LookupFlightInfo({required this.flightNumber});
}

class ClearFlightLookup extends TransportEvent {}
