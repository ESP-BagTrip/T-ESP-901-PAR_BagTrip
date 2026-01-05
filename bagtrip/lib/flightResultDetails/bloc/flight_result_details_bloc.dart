import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/service/flight_offer_price_service.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'flight_result_details_event.dart';
part 'flight_result_details_state.dart';

class FlightResultDetailsBloc
    extends Bloc<FlightResultDetailsEvent, FlightResultDetailsState> {
  FlightResultDetailsBloc() : super(FlightResultDetailsInitial()) {
    on<LoadFlightDetails>((event, emit) {
      emit(FlightResultDetailsLoaded(event.flight));
    });

    on<ConfirmFlightPrice>((event, emit) async {
      Flight? currentFlight;

      if (state is FlightResultDetailsLoaded) {
        currentFlight = (state as FlightResultDetailsLoaded).flight;
      } else if (state is FlightPriceConfirmed) {
        // If re-confirming (e.g. after price change), use the current flight in state
        currentFlight = (state as FlightPriceConfirmed).flight;
      }

      if (currentFlight != null) {
        // Emit confirming state
        emit(FlightPriceConfirming());

        try {
          if (currentFlight.rawJson == null) {
            throw Exception('Flight data missing for pricing');
          }

          final service = FlightOfferPriceService();
          final response = await service.confirmPrice(currentFlight.rawJson!);

          // Extract flight offer
          List<dynamic> flightOffers = [];
          Map<String, dynamic>? dictionaries;

          if (response['data'] != null &&
              response['data']['flightOffers'] != null) {
            flightOffers = response['data']['flightOffers'];
            if (response['dictionaries'] != null) {
              dictionaries = Map<String, dynamic>.from(
                response['dictionaries'],
              );
            } else if (response['data']['dictionaries'] != null) {
              dictionaries = Map<String, dynamic>.from(
                response['data']['dictionaries'],
              );
            }
          } else if (response['flightOffers'] != null) {
            flightOffers = response['flightOffers'];
            if (response['dictionaries'] != null) {
              dictionaries = Map<String, dynamic>.from(
                response['dictionaries'],
              );
            }
          }

          if (flightOffers.isEmpty) {
            throw Exception('No priced flight offers returned');
          }

          final newFlight = Flight.fromAmadeusJson(
            flightOffers.first,
            dictionaries: dictionaries,
          );

          // Compare prices (using a small epsilon for double comparison)
          bool priceChanged =
              (newFlight.price - currentFlight.price).abs() > 0.01;

          emit(
            FlightPriceConfirmed(
              newFlight,
              priceChanged: priceChanged,
              oldFlight: priceChanged ? currentFlight : null,
            ),
          );
        } catch (e) {
          emit(FlightPriceError(e.toString(), currentFlight));
        }
      }
    });
  }
}
