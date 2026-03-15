part of 'transport_bloc.dart';

abstract class TransportState {}

class TransportInitial extends TransportState {}

class TransportLoading extends TransportState {}

class TransportsLoaded extends TransportState {
  final List<ManualFlight> transports;
  final List<ManualFlight> mainFlights;
  final List<ManualFlight> internalFlights;

  TransportsLoaded({
    required this.transports,
    required this.mainFlights,
    required this.internalFlights,
  });
}

class TransportError extends TransportState {
  final AppError error;
  TransportError({required this.error});
}

class FlightLookupLoading extends TransportState {}

class FlightLookupLoaded extends TransportState {
  final FlightInfo info;
  FlightLookupLoaded({required this.info});
}

class FlightLookupError extends TransportState {
  final AppError error;
  FlightLookupError({required this.error});
}
