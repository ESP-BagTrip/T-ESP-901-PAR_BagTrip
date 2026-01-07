// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dateFormatHint => 'dd/mm/yyyy';

  @override
  String get travelClassTitle => 'Travel Class';

  @override
  String get passengersTitle => 'Passengers';

  @override
  String get searchFlightButton => 'Search Flight';

  @override
  String get errorAddAtLeastOneFlight => 'Please add at least one flight';

  @override
  String get errorFillAllFields => 'Please fill in all required fields';

  @override
  String get travelClassEconomy => 'Economy';

  @override
  String get travelClassPremiumEconomy => 'Premium Eco';

  @override
  String get travelClassBusiness => 'Business';

  @override
  String get travelClassFirst => 'First';

  @override
  String get tripTypeRoundTrip => 'Round-trip';

  @override
  String get tripTypeOneWay => 'One-way';

  @override
  String get tripTypeMultiCity => 'Multi-city';

  @override
  String get airportDepartureHint => 'Departure airport';

  @override
  String get airportArrivalHint => 'Arrival airport';

  @override
  String get passengersAdults => 'Adults';

  @override
  String get passengersChildren => 'Children';

  @override
  String get passengersInfants => 'Infants';

  @override
  String multiDestFlightTitle(int index) {
    return 'Flight $index';
  }

  @override
  String get multiDestDepartureHint => 'Departure';

  @override
  String get multiDestArrivalHint => 'Arrival';

  @override
  String get multiDestDateHint => 'Departure date';

  @override
  String get multiDestAddFlightButton => 'Add another flight';

  @override
  String get maxPriceHint => 'Max price (€)';

  @override
  String get noFlightsFoundTitle => 'No flights found';

  @override
  String get noFlightsFoundMessage => 'Try adjusting your search criteria.';

  @override
  String get noFlightsFoundPriceFilterMessage =>
      'No flights match your maximum budget. Try increasing your price limit or clearing the filter.';

  @override
  String get clearPriceFilterButton => 'Clear price filter';

  @override
  String get selectYourRate => 'Select your rate';

  @override
  String get outboundFlight => 'Outbound flight';

  @override
  String get returnFlight => 'Return flight';

  @override
  String stopsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
      zero: 'Direct flight',
    );
    return '$_temp0';
  }

  @override
  String get baggageIncluded => 'Baggage included';

  @override
  String get cabinBag => 'Cabin bag';

  @override
  String get checkedBag => 'Checked bag';

  @override
  String get classAndConditions => 'Class and conditions';

  @override
  String get bookingClass => 'Booking class';

  @override
  String get cabin => 'Cabin';

  @override
  String get fareBasis => 'Fare basis';

  @override
  String get fareInformation => 'Fare information';

  @override
  String ticketEmissionDeadline(String date) {
    return 'Ticket emission before $date';
  }

  @override
  String seatsRemaining(int count) {
    return '$count seat(s) remaining at this price';
  }

  @override
  String get baseFare => 'Base fare';

  @override
  String get taxesAndFees => 'Taxes and fees';

  @override
  String get totalPrice => 'Total price';

  @override
  String get bookThisFlight => 'Book this flight';

  @override
  String baggageKg(int weight) {
    return '$weight kg';
  }

  @override
  String baggageQuantity(int quantity) {
    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: '$quantity bags',
      one: '1 bag',
    );
    return '$_temp0';
  }

  @override
  String get baggageNotIncluded => 'Not included';

  @override
  String get handBaggageIncluded => 'Hand baggage included';

  @override
  String get unknown => 'Unknown';

  @override
  String get unknownAirline => 'Unknown airline';

  @override
  String get unknownAircraft => 'Unknown aircraft';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get searchResults => 'Search results';

  @override
  String get departureLabel => 'Departure';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get travelDatesLabel => 'Travel dates';

  @override
  String get outboundLabel => 'Outbound';

  @override
  String get returnLabel => 'Return';

  @override
  String get maxBudgetLabel => 'Maximum budget';

  @override
  String get flightCardTitle => 'Flight';

  @override
  String get hotelCardTitle => 'Hotel';

  @override
  String get flightAndHotelCardTitle => 'Flight + Hotel';

  @override
  String get otherCardTitle => 'Others';
}
