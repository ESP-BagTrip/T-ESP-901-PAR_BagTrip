import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bloc/bloc.dart';

part 'transport_event.dart';
part 'transport_state.dart';

class TransportBloc extends Bloc<TransportEvent, TransportState> {
  final TransportRepository _transportRepository;

  TransportBloc({TransportRepository? transportRepository})
    : _transportRepository =
          transportRepository ?? getIt<TransportRepository>(),
      super(TransportInitial()) {
    on<LoadTransports>(_onLoadTransports);
    on<CreateManualFlight>(_onCreateManualFlight);
    on<DeleteManualFlight>(_onDeleteManualFlight);
    on<LookupFlightInfo>(_onLookupFlightInfo);
    on<ClearFlightLookup>(_onClearFlightLookup);
  }

  Future<void> _onLoadTransports(
    LoadTransports event,
    Emitter<TransportState> emit,
  ) async {
    emit(TransportLoading());
    final result = await _transportRepository.getManualFlights(event.tripId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(
          TransportsLoaded(
            transports: data,
            mainFlights: data.where((f) => f.flightType == 'MAIN').toList(),
            internalFlights: data
                .where((f) => f.flightType == 'INTERNAL')
                .toList(),
          ),
        );
      case Failure(:final error):
        emit(TransportError(error: error));
    }
  }

  Future<void> _onCreateManualFlight(
    CreateManualFlight event,
    Emitter<TransportState> emit,
  ) async {
    final result = await _transportRepository.createManualFlight(
      event.tripId,
      event.data,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadTransports(tripId: event.tripId));
      case Failure(:final error):
        emit(TransportError(error: error));
    }
  }

  Future<void> _onDeleteManualFlight(
    DeleteManualFlight event,
    Emitter<TransportState> emit,
  ) async {
    final result = await _transportRepository.deleteManualFlight(
      event.tripId,
      event.flightId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        add(LoadTransports(tripId: event.tripId));
      case Failure(:final error):
        emit(TransportError(error: error));
    }
  }

  Future<void> _onLookupFlightInfo(
    LookupFlightInfo event,
    Emitter<TransportState> emit,
  ) async {
    emit(FlightLookupLoading());
    final result = await _transportRepository.lookupFlight(event.flightNumber);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(FlightLookupLoaded(info: data));
      case Failure(:final error):
        emit(FlightLookupError(error: error));
    }
  }

  Future<void> _onClearFlightLookup(
    ClearFlightLookup event,
    Emitter<TransportState> emit,
  ) async {
    emit(TransportInitial());
  }
}
