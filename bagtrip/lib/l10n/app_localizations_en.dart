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
  String get travelClassPremiumEconomy => 'Premium Economy';

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
}
