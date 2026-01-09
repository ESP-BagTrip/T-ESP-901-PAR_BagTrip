// ignore_for_file: depend_on_referenced_packages

import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/home/models/flight_segment.dart';
import 'package:bagtrip/service/flight_search_service.dart';
import 'package:bagtrip/service/LocationService.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'flight_search_result_event.dart';
part 'flight_search_result_state.dart';

class FlightSearchResultBloc
    extends Bloc<FlightSearchResultEvent, FlightSearchResultState> {
  final FlightSearchService _flightSearchService;

  FlightSearchResultBloc({
    FlightSearchService? flightSearchService,
    LocationService? locationService,
  }) : _flightSearchService = flightSearchService ?? FlightSearchService(),
       super(FlightSearchResultInitial()) {
    on<LoadFlights>(_onLoadFlights);
    on<FilterFlightsByPrice>(_onFilterFlightsByPrice);
    on<SortFlights>(_onSortFlights);
    on<SelectFlight>(_onSelectFlight);
    on<SelectDate>(_onSelectDate);
    on<ApplyFilters>(_onApplyFilters);
  }

  FlightSearchResultLoaded _currentState() {
    if (state is FlightSearchResultLoaded) {
      return state as FlightSearchResultLoaded;
    }
    return FlightSearchResultLoaded(
      flights: [],
      filteredFlights: [],
      departureDate: DateTime.now(),
      tripId: '',
      departureCode: '',
      arrivalCode: '',
      adults: 1,
      children: 0,
      infants: 0,
      travelClass: 'ECONOMY',
    );
  }

  Future<void> _onLoadFlights(
    LoadFlights event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    emit(FlightSearchResultLoading());

    try {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final departureDateStr = dateFormatter.format(event.departureDate);
      final returnDateStr =
          event.returnDate != null
              ? dateFormatter.format(event.returnDate!)
              : null;

      // Use trip-based search
      final searchResponse = await _flightSearchService.searchFlights(
        event.tripId,
        originIata: event.departureCode,
        destinationIata: event.arrivalCode,
        departureDate: departureDateStr,
        returnDate: returnDateStr,
        adults: event.adults,
        children: event.children,
        infants: event.infants,
        travelClass: event.travelClass.toUpperCase(),
      );

      // Fetch full details for each offer to create Flight objects
      final flights = <Flight>[];
      for (final offer in searchResponse.offers) {
        try {
          final offerDetails = await _flightSearchService.getFlightOffer(
            event.tripId,
            offer.id,
          );
          // Parse the offer JSON to create Flight object
          if (offerDetails['offer'] != null) {
            final flight = Flight.fromAmadeusJson(
              offerDetails['offer'] as Map<String, dynamic>,
              databaseOfferId: offer.id, // Pass the database offer ID
            );
            flights.add(flight);
          }
        } catch (e) {
          // If we can't get full details, create a simplified flight from summary
          // This is a fallback - ideally all offers should have full details
          debugPrint(
            'Warning: Could not fetch full details for offer ${offer.id}: $e',
          );
        }
      }

      var filteredFlights = List<Flight>.from(flights);
      if (event.maxPrice != null) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.price <= event.maxPrice!)
                .toList();
      }

      emit(
        FlightSearchResultLoaded(
          flights: flights,
          filteredFlights: filteredFlights,
          maxPrice: event.maxPrice,
          departureDate: event.departureDate,
          returnDate: event.returnDate,
          tripId: event.tripId,
          searchId: searchResponse.searchId,
          departureCode: event.departureCode,
          arrivalCode: event.arrivalCode,
          adults: event.adults,
          children: event.children,
          infants: event.infants,
          travelClass: event.travelClass,
          multiDestSegments: event.multiDestSegments,
        ),
      );
    } catch (e) {
      emit(FlightSearchResultError(e.toString()));
    }
  }

  Future<void> _onFilterFlightsByPrice(
    FilterFlightsByPrice event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    List<Flight> filtered;

    if (event.maxPrice != null) {
      filtered =
          current.flights
              .where((flight) => flight.price <= event.maxPrice!)
              .toList();
    } else {
      filtered = List.from(current.flights);
    }

    emit(current.copyWith(filteredFlights: filtered, maxPrice: event.maxPrice));
  }

  Future<void> _onSortFlights(
    SortFlights event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    final sorted = List<Flight>.from(current.filteredFlights);

    switch (event.sortBy) {
      case 'price':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'duration':
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'departure':
        sorted.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }

    emit(current.copyWith(filteredFlights: sorted, sortBy: event.sortBy));
  }

  Future<void> _onSelectFlight(
    SelectFlight event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    emit(current.copyWith(selectedFlight: event.flight));
  }

  Future<void> _onSelectDate(
    SelectDate event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();

    // Don't reload if same date is already selected
    if (current.selectedDateIndex == event.dateIndex) {
      return;
    }

    // Calculate new departure date based on index
    // The dates are: [departureDate - 1, departureDate, departureDate + 1]
    // So index 0 = -1 day, index 1 = base date (0 offset), index 2 = +1 day
    final daysOffset = event.dateIndex - 1;
    final newDepartureDate = current.departureDate.add(
      Duration(days: daysOffset),
    );

    // If return date exists, adjust it by the same offset to maintain trip duration
    final newReturnDate = current.returnDate?.add(Duration(days: daysOffset));

    // Reload flights with new date
    emit(FlightSearchResultLoading());

    try {
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final departureDateStr = dateFormatter.format(newDepartureDate);
      final returnDateStr =
          newReturnDate != null ? dateFormatter.format(newReturnDate) : null;

      // Use trip-based search
      final searchResponse = await _flightSearchService.searchFlights(
        current.tripId,
        originIata: current.departureCode,
        destinationIata: current.arrivalCode,
        departureDate: departureDateStr,
        returnDate: returnDateStr,
        adults: current.adults,
        children: current.children,
        infants: current.infants,
        travelClass: current.travelClass.toUpperCase(),
      );

      // Fetch full details for each offer
      final flights = <Flight>[];
      for (final offer in searchResponse.offers) {
        try {
          final offerDetails = await _flightSearchService.getFlightOffer(
            current.tripId,
            offer.id,
          );
          if (offerDetails['offer'] != null) {
            final flight = Flight.fromAmadeusJson(
              offerDetails['offer'] as Map<String, dynamic>,
              databaseOfferId: offer.id, // Pass the database offer ID
            );
            flights.add(flight);
          }
        } catch (e) {
          debugPrint(
            'Warning: Could not fetch full details for offer ${offer.id}: $e',
          );
        }
      }

      var filteredFlights = List<Flight>.from(flights);

      // Reapply all existing filters
      if (current.maxPrice != null) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.price <= current.maxPrice!)
                .toList();
      }

      if (current.selectedAirline != null &&
          current.selectedAirline!.isNotEmpty) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.airline == current.selectedAirline)
                .toList();
      }

      if (current.cabinBagIncluded == true) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.cabinBags != null)
                .toList();
      }

      if (current.checkedBagIncluded == true) {
        filteredFlights =
            filteredFlights
                .where((flight) => flight.checkedBags != null)
                .toList();
      }

      if (current.departureTimeBefore != null ||
          current.departureTimeAfter != null) {
        filteredFlights =
            filteredFlights.where((flight) {
              if (flight.departureDateTime == null) return false;
              final flightTime = TimeOfDay.fromDateTime(
                flight.departureDateTime!,
              );

              if (current.departureTimeBefore != null) {
                final before = current.departureTimeBefore!;
                final flightMinutes = flightTime.hour * 60 + flightTime.minute;
                final beforeMinutes = before.hour * 60 + before.minute;
                if (flightMinutes >= beforeMinutes) {
                  return false;
                }
              }

              if (current.departureTimeAfter != null) {
                final after = current.departureTimeAfter!;
                final flightMinutes = flightTime.hour * 60 + flightTime.minute;
                final afterMinutes = after.hour * 60 + after.minute;
                if (flightMinutes <= afterMinutes) {
                  return false;
                }
              }

              return true;
            }).toList();
      }

      // Apply price sort if set
      if (current.priceSort != null) {
        if (current.priceSort == 'lowest') {
          filteredFlights.sort((a, b) => a.price.compareTo(b.price));
        } else if (current.priceSort == 'highest') {
          filteredFlights.sort((a, b) => b.price.compareTo(a.price));
        }
      }

      emit(
        FlightSearchResultLoaded(
          flights: flights,
          filteredFlights: filteredFlights,
          maxPrice: current.maxPrice,
          sortBy: current.sortBy,
          departureDate: newDepartureDate,
          returnDate: newReturnDate,
          tripId: current.tripId,
          searchId: searchResponse.searchId,
          departureCode: current.departureCode,
          arrivalCode: current.arrivalCode,
          adults: current.adults,
          children: current.children,
          infants: current.infants,
          travelClass: current.travelClass,
          multiDestSegments: current.multiDestSegments,
          selectedDateIndex:
              1, // The newly loaded date becomes the center date (index 1)
          priceSort: current.priceSort,
          selectedAirline: current.selectedAirline,
          cabinBagIncluded: current.cabinBagIncluded,
          checkedBagIncluded: current.checkedBagIncluded,
          departureTimeBefore: current.departureTimeBefore,
          departureTimeAfter: current.departureTimeAfter,
        ),
      );
    } catch (e) {
      emit(FlightSearchResultError(e.toString()));
    }
  }

  Future<void> _onApplyFilters(
    ApplyFilters event,
    Emitter<FlightSearchResultState> emit,
  ) async {
    final current = _currentState();
    var filtered = List<Flight>.from(current.flights);

    // Apply price filter (max price)
    if (current.maxPrice != null) {
      filtered =
          filtered
              .where((flight) => flight.price <= current.maxPrice!)
              .toList();
    }

    // Apply airline filter
    if (event.selectedAirline != null && event.selectedAirline!.isNotEmpty) {
      filtered =
          filtered
              .where((flight) => flight.airline == event.selectedAirline)
              .toList();
    }

    // Apply cabin bag filter
    if (event.cabinBagIncluded == true) {
      filtered = filtered.where((flight) => flight.cabinBags != null).toList();
    }

    // Apply checked bag filter
    if (event.checkedBagIncluded == true) {
      filtered =
          filtered.where((flight) => flight.checkedBags != null).toList();
    }

    // Apply departure time filters
    if (event.departureTimeBefore != null || event.departureTimeAfter != null) {
      filtered =
          filtered.where((flight) {
            if (flight.departureDateTime == null) return false;
            final flightTime = TimeOfDay.fromDateTime(
              flight.departureDateTime!,
            );

            // Before: flight must depart before the specified time
            if (event.departureTimeBefore != null) {
              final before = event.departureTimeBefore!;
              final flightMinutes = flightTime.hour * 60 + flightTime.minute;
              final beforeMinutes = before.hour * 60 + before.minute;
              if (flightMinutes >= beforeMinutes) {
                return false;
              }
            }

            // After: flight must depart after the specified time
            if (event.departureTimeAfter != null) {
              final after = event.departureTimeAfter!;
              final flightMinutes = flightTime.hour * 60 + flightTime.minute;
              final afterMinutes = after.hour * 60 + after.minute;
              if (flightMinutes <= afterMinutes) {
                return false;
              }
            }

            return true;
          }).toList();
    }

    // Apply price sort (lowest or highest)
    if (event.priceSort != null) {
      if (event.priceSort == 'lowest') {
        filtered.sort((a, b) => a.price.compareTo(b.price));
      } else if (event.priceSort == 'highest') {
        filtered.sort((a, b) => b.price.compareTo(a.price));
      }
    }

    emit(
      current.copyWith(
        filteredFlights: filtered,
        priceSort: event.priceSort,
        selectedAirline: event.selectedAirline,
        cabinBagIncluded: event.cabinBagIncluded,
        checkedBagIncluded: event.checkedBagIncluded,
        departureTimeBefore: event.departureTimeBefore,
        departureTimeAfter: event.departureTimeAfter,
      ),
    );
  }
}
