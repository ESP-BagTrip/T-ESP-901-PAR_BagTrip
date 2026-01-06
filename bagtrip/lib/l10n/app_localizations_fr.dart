// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get dateFormatHint => 'jj/mm/aaaa';

  @override
  String get travelClassTitle => 'Classe de voyage';

  @override
  String get passengersTitle => 'Passagers';

  @override
  String get searchFlightButton => 'Rechercher votre vol';

  @override
  String get errorAddAtLeastOneFlight => 'Veuillez ajouter au moins un vol';

  @override
  String get errorFillAllFields =>
      'Veuillez remplir tous les champs obligatoires';

  @override
  String get travelClassEconomy => 'Économique';

  @override
  String get travelClassPremiumEconomy => 'Premium Économique';

  @override
  String get travelClassBusiness => 'Affaires';

  @override
  String get travelClassFirst => 'Première';

  @override
  String get tripTypeRoundTrip => 'Aller-retour';

  @override
  String get tripTypeOneWay => 'Aller simple';

  @override
  String get tripTypeMultiCity => 'Multi-destinations';

  @override
  String get airportDepartureHint => 'Aéroport de départ';

  @override
  String get airportArrivalHint => 'Aéroport de destination';

  @override
  String get passengersAdults => 'Adultes';

  @override
  String get passengersChildren => 'Enfants';

  @override
  String get passengersInfants => 'Bébés';

  @override
  String multiDestFlightTitle(int index) {
    return 'Vol $index';
  }

  @override
  String get multiDestDepartureHint => 'Départ';

  @override
  String get multiDestArrivalHint => 'Arrivée';

  @override
  String get multiDestDateHint => 'Date de départ';

  @override
  String get multiDestAddFlightButton => 'Ajouter un autre vol';

  @override
  String get maxPriceHint => 'Prix maximum (€)';

  @override
  String get noFlightsFoundTitle => 'Aucun vol trouvé';

  @override
  String get noFlightsFoundMessage =>
      'Essayez de modifier vos critères de recherche.';

  @override
  String get noFlightsFoundPriceFilterMessage =>
      'Aucun vol ne correspond à votre budget maximum. Essayez d\'augmenter votre limite de prix ou d\'effacer le filtre.';

  @override
  String get clearPriceFilterButton => 'Effacer le filtre de prix';

  @override
  String get selectYourRate => 'Sélectionnez votre tarif';

  @override
  String get outboundFlight => 'Vol aller';

  @override
  String get returnFlight => 'Vol retour';

  @override
  String stopsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escales',
      one: '1 escale',
      zero: 'Vol direct',
    );
    return '$_temp0';
  }

  @override
  String get baggageIncluded => 'Bagages inclus';

  @override
  String get cabinBag => 'Bagage cabine';

  @override
  String get checkedBag => 'Bagage en soute';

  @override
  String get classAndConditions => 'Classe et conditions';

  @override
  String get bookingClass => 'Classe de réservation';

  @override
  String get cabin => 'Cabine';

  @override
  String get fareBasis => 'Code tarifaire';

  @override
  String get fareInformation => 'Informations tarifaires';

  @override
  String ticketEmissionDeadline(String date) {
    return 'Émission du billet avant le $date';
  }

  @override
  String seatsRemaining(int count) {
    return '$count siège(s) restant(s) à ce tarif';
  }

  @override
  String get baseFare => 'Tarif de base';

  @override
  String get taxesAndFees => 'Taxes et frais';

  @override
  String get totalPrice => 'Prix total';

  @override
  String get bookThisFlight => 'Réserver ce vol';

  @override
  String baggageKg(int weight) {
    return '$weight kg';
  }

  @override
  String baggageQuantity(int quantity) {
    String _temp0 = intl.Intl.pluralLogic(
      quantity,
      locale: localeName,
      other: '$quantity bagages',
      one: '1 bagage',
    );
    return '$_temp0';
  }

  @override
  String get baggageNotIncluded => 'Non inclus';

  @override
  String get handBaggageIncluded => 'Bagage à main inclus';

  @override
  String get unknown => 'Inconnu';

  @override
  String get unknownAirline => 'Compagnie inconnue';

  @override
  String get unknownAircraft => 'Appareil inconnu';

  @override
  String error(String message) {
    return 'Erreur : $message';
  }

  @override
  String get searchResults => 'Résultats de recherche';

  @override
  String get departureLabel => 'Départ';

  @override
  String get destinationLabel => 'Destination';

  @override
  String get travelDatesLabel => 'Dates de voyage';

  @override
  String get outboundLabel => 'Aller';

  @override
  String get returnLabel => 'Retour';

  @override
  String get maxBudgetLabel => 'Budget maximum';

  @override
  String get flightCardTitle => 'Vol';

  @override
  String get hotelCardTitle => 'Hôtel';

  @override
  String get flightAndHotelCardTitle => 'Vol + Hôtel';

  @override
  String get otherCardTitle => 'Autres';
}
