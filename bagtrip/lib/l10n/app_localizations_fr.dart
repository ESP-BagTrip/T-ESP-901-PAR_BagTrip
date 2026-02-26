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
  String get travelClassPremiumEconomy => 'Premium Éco';

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
  String get passengersAdultsDesc => '12 ans et plus';

  @override
  String get passengersChildren => 'Enfants';

  @override
  String get passengersChildrenDesc => '2-11 ans';

  @override
  String get passengersInfants => 'Bébés';

  @override
  String get passengersInfantsDesc => 'Moins de 2 ans';

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

  @override
  String get handleBudget => 'Gérer votre budget';

  @override
  String get trackExpensesAndPlan =>
      'Suivez vos dépenses et planifiez votre voyage selon votre budget';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get managePersonalInfo =>
      'Gérez vos informations personnelles et vos préférences';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get disconnect => 'Se déconnecter';

  @override
  String get viewDestinations => 'Visualiser les destinations';

  @override
  String get exploreDestinations =>
      'Explorez les destinations disponibles sur une carte interactive';

  @override
  String get startButton => 'Commencer';

  @override
  String get newTrip => 'Nouveau voyage';

  @override
  String get createYourTrip => 'Créez votre voyage';

  @override
  String get nameTripToStart =>
      'Donnez un nom à votre voyage pour commencer la planification';

  @override
  String get tripNameLabel => 'Nom du voyage';

  @override
  String get tripNameHint => 'Ex: Vacances à Paris';

  @override
  String get continueButton => 'Continuer';

  @override
  String get aiPlanning => 'Planification IA';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get searchingInProgress => 'Recherche en cours...';

  @override
  String get typeYourMessage => 'Tapez votre message...';

  @override
  String planningTitle(String title) {
    return 'Planification $title';
  }

  @override
  String get personalInfoTitle => 'Informations personnelles';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get phoneLabel => 'TÉLÉPHONE';

  @override
  String get addressLabel => 'ADRESSE';

  @override
  String get modifyButton => 'Modifier';

  @override
  String get preferencesTitle => 'Préférences';

  @override
  String get languageLabel => 'LANGUE';

  @override
  String get themeLabel => 'THÈME';

  @override
  String get chooseThemeHint => 'Choisissez votre thème préféré';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String profileFooterText(String version, int year) {
    return 'Version $version · © $year Vol Airlines';
  }

  @override
  String memberSinceText(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get recentBookingsTitle => 'Réservations récentes';

  @override
  String get viewAllButton => 'Voir tout';

  @override
  String get noRecentBookings => 'Aucune réservation récente';

  @override
  String get bookingStatusCompleted => 'Terminé';

  @override
  String get bookingStatusConfirmed => 'Confirmé';

  @override
  String get profileLoadFailureMessage => 'Impossible de charger le profil.';

  @override
  String get loginWelcomeTitle => 'Bienvenue sur Bag Trip';

  @override
  String get loginWelcomeSubtitle =>
      'Connectez-vous ou créez un compte pour accéder à votre espace';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'Inscription';

  @override
  String get loginOrContinueWithEmail => 'OU CONTINUER AVEC L\'EMAIL';

  @override
  String get loginEmailPlaceholder => 'Adresse e-mail';

  @override
  String get loginPasswordPlaceholder => 'Mot de passe';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginButton => 'Connexion';

  @override
  String get loginLegalBySigningIn => 'En vous connectant, vous acceptez les ';

  @override
  String get loginTermsOfService => 'Conditions d\'utilisation';

  @override
  String get loginPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get loginLegalAnd => ' et ';

  @override
  String get loginContinueWithGoogle => 'Google';

  @override
  String get loginContinueWithApple => 'Apple';

  @override
  String get loginFullNameLabel => 'Nom complet (optionnel)';

  @override
  String get loginFullNameHint => 'Jean Dupont';

  @override
  String get loginToggleNoAccount => 'Pas de compte ? S\'inscrire';

  @override
  String get loginToggleHasAccount => 'Déjà un compte ? Se connecter';

  @override
  String get loginErrorEmailRequired =>
      'Veuillez renseigner votre adresse e-mail';

  @override
  String get loginErrorEmailInvalid => 'Adresse e-mail incorrecte';

  @override
  String get loginErrorPasswordRequired =>
      'Veuillez renseigner votre mot de passe';

  @override
  String get loginErrorPasswordMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get loginRegisterButton => 'S\'inscrire';

  @override
  String get onboardingTitle => 'Bienvenue !';

  @override
  String get onboardingSubtitle =>
      'Personnalisons votre expérience de voyage en quelques étapes simples.';

  @override
  String get onboardingFeature1Title => 'Planification simplifiée';

  @override
  String get onboardingFeature1Desc =>
      'Créez votre voyage en quelques étapes. Plus besoin de jongler entre mille onglets.';

  @override
  String get onboardingFeature2Title => 'Voyage personnalisé';

  @override
  String get onboardingFeature2Desc =>
      'Chaque voyage s\'adapte à vos envies, votre budget et votre rythme.';

  @override
  String get onboardingFeature3Title => 'IA à votre service';

  @override
  String get onboardingFeature3Desc =>
      'Pas d\'idée de destination ? Notre IA vous guide vers le voyage parfait.';

  @override
  String get onboardingCtaButton => 'Commencer';

  @override
  String get onboardingSkip => 'Passer l\'introduction';

  @override
  String get splashLoading => 'Chargement...';

  @override
  String get personalizationPromptTitle => 'Personnalisez votre expérience';

  @override
  String get personalizationPromptSubtitle =>
      'Quelques questions pour mieux vous connaître et vous proposer des voyages sur mesure.';

  @override
  String get personalizationOptionTravelTypes => 'Vos types de voyage préférés';

  @override
  String get personalizationOptionBudget => 'Votre budget habituel';

  @override
  String get personalizationOptionCompanions => 'Avec qui vous voyagez';

  @override
  String get personalizationCompleteProfile => 'Compléter mon profil >';

  @override
  String get personalizationSkipStep => 'Passer cette étape';

  @override
  String get personalizationProfileSectionTitle =>
      'Personnalisation de l\'expérience';

  @override
  String get personalizationPageTitle => 'Mon profil voyage';

  @override
  String get personalizationDone => 'Terminer';

  @override
  String get personalizationStepTitleTravelTypes =>
      'Vos types de voyage préférés';

  @override
  String get personalizationStepSubtitleTravelTypes =>
      'Sélectionnez un ou plusieurs types';

  @override
  String get personalizationTravelTypeBeach => 'Plage & Détente';

  @override
  String get personalizationTravelTypeAdventure => 'Aventure & Nature';

  @override
  String get personalizationTravelTypeCity => 'Ville & Culture';

  @override
  String get personalizationTravelTypeGastronomy => 'Gastronomie';

  @override
  String get personalizationTravelTypeWellness => 'Bien-être & Spa';

  @override
  String get personalizationTravelTypeNightlife => 'Fête & Vie nocturne';

  @override
  String get personalizationStepTitleTravelStyle => 'Votre style de voyage';

  @override
  String get personalizationStepSubtitleTravelStyle =>
      'Comment aimez-vous organiser vos voyages ?';

  @override
  String get personalizationTravelStylePlanned => 'Tout planifié';

  @override
  String get personalizationTravelStyleFlexible => 'Flexible';

  @override
  String get personalizationTravelStyleSpontaneous => 'Spontané';

  @override
  String get personalizationStepTitleBudget => 'Votre budget habituel';

  @override
  String get personalizationStepSubtitleBudget =>
      'Quel est votre niveau de dépense préféré ?';

  @override
  String get personalizationBudgetEconomical => 'Économique';

  @override
  String get personalizationBudgetEconomicalDesc =>
      'Auberges, transports locaux';

  @override
  String get personalizationBudgetModerate => 'Modéré';

  @override
  String get personalizationBudgetModerateDesc => 'Hôtels 3★, confort';

  @override
  String get personalizationBudgetLuxury => 'Luxe';

  @override
  String get personalizationBudgetLuxuryDesc => 'Hôtels 5★, expériences VIP';

  @override
  String get personalizationStepTitleCompanions => 'Avec qui voyagez-vous ?';

  @override
  String get personalizationStepSubtitleCompanions =>
      'Généralement, vous voyagez...';

  @override
  String get personalizationCompanionSolo => 'Solo';

  @override
  String get personalizationCompanionCouple => 'En couple';

  @override
  String get personalizationCompanionFamily => 'En famille';

  @override
  String get personalizationCompanionFriends => 'Entre amis';

  @override
  String get personalizationContinue => 'Continuer';

  @override
  String get personalizationFinish => 'Terminer';

  @override
  String get personalizationSkip => 'Passer';

  @override
  String get planifierTab => 'Planifier';

  @override
  String get planifierSectionCreateTrip => 'Créer un voyage';

  @override
  String get planifierManualTitle => 'Planifier manuellement';

  @override
  String get planifierManualDesc =>
      'Créez votre voyage étape par étape avec tous les détails';

  @override
  String get planifierAITitle => 'Assistant IA';

  @override
  String get planifierAIDesc =>
      'Laissez l\'IA vous aider à créer un voyage personnalisé';

  @override
  String get planifierSectionMyTrips => 'Mes voyages';

  @override
  String get planifierInProgressTitle => 'En cours de planification';

  @override
  String planifierInProgressCount(int count) {
    return '$count voyage(s) en attente';
  }

  @override
  String get planifierCompletedTitle => 'Voyages terminés';

  @override
  String get planifierCompletedDesc =>
      'Consultez vos voyages passés et budgets';
}
