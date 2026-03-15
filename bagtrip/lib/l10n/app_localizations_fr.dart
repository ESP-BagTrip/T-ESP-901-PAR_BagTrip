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
  String get whereNextLabel => 'Quel est votre prochain voyage';

  @override
  String get findYourFlightTitle => 'Trouvez votre vol';

  @override
  String get departLabel => 'Départ';

  @override
  String get cabinClassLabel => 'Classe';

  @override
  String get tripDetailsLabel => 'Détails du voyage';

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
  String get personalizationWelcomeTitle => 'Bienvenue';

  @override
  String get personalizationWelcomeSubtitle =>
      'Personnalisons votre expérience de voyage';

  @override
  String get personalizationWelcomeCta => 'Commencer';

  @override
  String get personalizationStepTitleHowYouTravel => 'Comment voyagez-vous ?';

  @override
  String get personalizationStepTitleInterests => 'Vos centres d\'intérêt';

  @override
  String get personalizationStepSubtitleInterests =>
      'Sélectionnez un ou plusieurs';

  @override
  String get personalizationStepTitleBudgetQuestion =>
      'Quel est votre budget ?';

  @override
  String get personalizationStepTitleFrequency =>
      'À quelle fréquence voyagez-vous ?';

  @override
  String get personalizationStepSubtitleFrequency => 'Par an';

  @override
  String get personalizationBudgetComfort => 'Confort';

  @override
  String get personalizationBudgetComfortDesc => 'Hôtels 4★, bon équilibre';

  @override
  String get personalizationFrequency1_2 => '1–2 fois';

  @override
  String get personalizationFrequency3_5 => '3–5 fois';

  @override
  String get personalizationFrequency6Plus => '6+ fois';

  @override
  String get personalizationInterestPhotography => 'Photographie';

  @override
  String get personalizationInterestShopping => 'Shopping';

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

  @override
  String get planifierGreeting => 'Bonjour';

  @override
  String get planifierMainTitle => 'Planifiez votre\nprochain voyage';

  @override
  String get planifierSubtitle => 'Créez et gérez vos voyages';

  @override
  String get planifierManualDescriptionCard =>
      'Construisez votre itinéraire étape par étape.';

  @override
  String get planifierAIDescriptionCard =>
      'Laissez l\'IA créer un voyage personnalisé pour vous.';

  @override
  String get planifierNewBadge => 'NOUVEAU';

  @override
  String get planifierPlanningTitle => 'En cours';

  @override
  String get planifierPlanningDescription => 'Voyages en préparation';

  @override
  String planifierInProgressSuffix(int count) {
    return '$count en cours';
  }

  @override
  String get planifierCompletedShort => 'Terminés';

  @override
  String get planifierCompletedDescriptionCard => 'Voyages passés et budgets';

  @override
  String planifierCompletedSuffix(int count) {
    return '$count terminés';
  }

  @override
  String get planifierSectionExploreDestinations => 'Explorer les destinations';

  @override
  String get destinationKyoto => 'Kyoto';

  @override
  String get destinationSantorini => 'Santorini';

  @override
  String get destinationMarrakech => 'Marrakech';

  @override
  String get countryJapan => 'JAPAN';

  @override
  String get countryGreece => 'GREECE';

  @override
  String get countryMorocco => 'MOROCCO';

  @override
  String get yourDestinationTitle => 'Votre destination';

  @override
  String get destinationPlaceholder => 'Paris, Tokyo, New York...';

  @override
  String get numberOfTravelersLabel => 'Nombre de voyageurs';

  @override
  String get nextButton => 'Suivant';

  @override
  String get travelerCount5Plus => '5+';

  @override
  String get transportTitle => 'Transport';

  @override
  String get transportOptionFlightTitle => 'Oui, chercher un vol';

  @override
  String get transportOptionFlightSubtitle => 'Recherche via Amadeus';

  @override
  String get transportOptionOtherTitle => 'Non, autre transport';

  @override
  String get transportOptionOtherSubtitle => 'Voiture, train, bus...';

  @override
  String get transportOptionSkipTitle => 'Non, passer cette étape';

  @override
  String get transportOptionSkipSubtitle => 'Aucun transport à ajouter';

  @override
  String get otherTransportTitle => 'Autres transport';

  @override
  String get transportTypeLabel => 'Type de transport';

  @override
  String get transportTypeCar => 'Voiture';

  @override
  String get transportTypeTrain => 'Train';

  @override
  String get transportTypeBus => 'Bus';

  @override
  String get transportTypeFlightBooked => 'Vol (déjà réservé)';

  @override
  String get transportDetailsLabel => 'Détails (optionnel)';

  @override
  String get transportDetailsPlaceholder =>
      'Ex: Location chez Hertz, TGV Paris-Lyon...';

  @override
  String get transportBudgetLabel => 'Budget transport (€)';

  @override
  String get transportBudgetPlaceholder => 'Ex: 150';

  @override
  String get transportBudgetHint =>
      'Ce montant sera ajouté à votre budget voyage';

  @override
  String get skipThisStepLabel => 'Passer cette étape';

  @override
  String get recapTitle => 'Récapitulatif';

  @override
  String get recapFinalStepLabel => 'ÉTAPE FINALE';

  @override
  String get recapDateChoose => 'Choisir';

  @override
  String get recapDateSelectHint => 'Sélectionner';

  @override
  String get recapTravelTypesLabel => 'TYPES DE VOYAGE';

  @override
  String get recapStyleLabel => 'STYLE';

  @override
  String get recapBudgetLabel => 'BUDGET';

  @override
  String get recapCompanionsLabel => 'COMPAGNONS';

  @override
  String get recapLaunchSearchButton => 'Lancer la recherche IA';

  @override
  String get summaryTitle => 'Votre voyage personnalisé';

  @override
  String get summarySubtitle => '+ Généré par l\'IA';

  @override
  String get summaryUpcomingJourney => '◆ PROCHAIN VOYAGE';

  @override
  String get summaryDays => 'jours';

  @override
  String get summaryBudget => 'budget';

  @override
  String get summarySolo => 'Solo';

  @override
  String get summarySectionCurated => 'POUR VOUS';

  @override
  String get summaryTripHighlights => 'Points forts du voyage';

  @override
  String get summarySectionWhereStay => 'OÙ LOGER';

  @override
  String get summaryAccommodation => 'Hébergement';

  @override
  String get summarySectionFlight => 'VOL';

  @override
  String get summaryFlight => 'Vol';

  @override
  String get summaryFlightRouteMock => 'Paris CDG → Paris Orly';

  @override
  String get summaryFlightDetailsMock => 'Aller-retour · Économique';

  @override
  String get summarySectionYourJourney => 'VOTRE VOYAGE';

  @override
  String get summaryDayByDay => 'Jour par jour';

  @override
  String get summarySectionEssentials => 'ESSENTIELS';

  @override
  String get summaryWhatToBring => 'À emporter';

  @override
  String get summaryBestPick => 'Best pick';

  @override
  String get summaryDayPrefix => 'J';

  @override
  String get summaryDay1Date => 'LUNDI · 9 JUIN';

  @override
  String get summaryDay2Date => 'MARDI · 10 JUIN';

  @override
  String get summaryDay3Date => 'MERCREDI · 11 JUIN';

  @override
  String get summaryDay4Date => 'JEUDI · 12 JUIN';

  @override
  String get summaryDay5Date => 'VENDREDI · 13 JUIN';

  @override
  String get summaryDay1Description =>
      'Installation au Marais, balade dans les rues historiques, apéritif en soirée place des Vosges.';

  @override
  String get summaryDay2Description =>
      'Louvre le matin, quartier Notre-Dame, berges de la Seine l\'après-midi.';

  @override
  String get summaryDay3Description =>
      'Atelier cuisine, marché, dîner dans un bistro typique.';

  @override
  String get summaryDay4Description =>
      'Château de Versailles, la Galerie des Glaces et les jardins en fleurs.';

  @override
  String get summaryDay5Description =>
      'Matin à Sacré-Cœur, dernier café crème, vol retour l\'après-midi.';

  @override
  String get summaryCategoryTravelDay => 'Jour de voyage';

  @override
  String get summaryCategoryCulture => 'Culture';

  @override
  String get summaryCategoryCuisine => 'Cuisine';

  @override
  String get summaryCategoryDayTrip => 'Excursion';

  @override
  String get summaryCategoryDeparture => 'Départ';

  @override
  String get summarySaveTrip => 'Sauvegarder ce voyage';

  @override
  String get summaryRegenerate => 'Régénérer';

  @override
  String get summaryTripSaved => 'Voyage sauvegardé';

  @override
  String summaryDaysCount(int count) {
    return '$count jours';
  }

  @override
  String summaryBudgetAmount(String amount) {
    return '$amount budget';
  }

  @override
  String get activities => 'Activités';

  @override
  String get addActivity => 'Ajouter une activité';

  @override
  String get editActivity => 'Modifier l’activité';

  @override
  String get noActivities => 'Aucune activité';

  @override
  String get activityTitle => 'Titre';

  @override
  String get activityDate => 'Date';

  @override
  String get activityDescription => 'Description';

  @override
  String get activityStartTime => 'Heure de début';

  @override
  String get activityEndTime => 'Heure de fin';

  @override
  String get activityLocation => 'Lieu';

  @override
  String get activityCategory => 'Catégorie';

  @override
  String get activityEstimatedCost => 'Coût estimé';

  @override
  String get activityBooked => 'Réservé';

  @override
  String get categoryVisit => 'Visite';

  @override
  String get categoryRestaurant => 'Restaurant';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryLeisure => 'Loisir';

  @override
  String get categoryOther => 'Autre';

  @override
  String get budgetItems => 'Budget';

  @override
  String get editExpense => 'Modifier la dépense';

  @override
  String get noExpenses => 'Aucune dépense';

  @override
  String get expenseLabel => 'Libellé';

  @override
  String get expenseAmount => 'Montant';

  @override
  String get expenseCategory => 'Catégorie';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensePlanned => 'Planifié';

  @override
  String get expenseReal => 'Réel';

  @override
  String get budgetTotal => 'Budget total';

  @override
  String get budgetSpent => 'Dépensé';

  @override
  String get budgetRemaining => 'Restant';

  @override
  String get categoryFlight => 'Vol';

  @override
  String get categoryAccommodation => 'Hébergement';

  @override
  String get categoryFood => 'Nourriture';

  @override
  String get categoryActivity => 'Activité';

  @override
  String budgetExceeded(String amount) {
    return 'Budget dépassé de $amount €';
  }

  @override
  String budgetWarning(String percent) {
    return 'Vous avez utilisé $percent% de votre budget';
  }

  @override
  String get tripCompletedReadOnly =>
      'Ce voyage est terminé. Les données sont en lecture seule.';

  @override
  String get markAsReady => 'Marquer comme prêt';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get addButton => 'Ajouter';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get errorTitle => 'Erreur';

  @override
  String get backButton => 'Retour';

  @override
  String get tabNew => 'Nouveau';

  @override
  String get tabTrips => 'Voyages';

  @override
  String get tabProfile => 'Profil';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Tout marquer lu';

  @override
  String get notificationsEmpty => 'Aucune notification';

  @override
  String get notificationsToday => 'Aujourd\'hui';

  @override
  String get notificationsYesterday => 'Hier';

  @override
  String notificationsDaysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get baggageTitle => 'Bagages';

  @override
  String get baggageSuggestionsTooltip => 'Suggestions IA';

  @override
  String get baggageCategoryDocuments => 'Documents';

  @override
  String get baggageCategoryClothing => 'Vêtements';

  @override
  String get baggageCategoryElectronics => 'Électronique';

  @override
  String get baggageCategoryHygiene => 'Hygiène';

  @override
  String get baggageCategoryMedication => 'Médicaments';

  @override
  String get baggageCategoryAccessories => 'Accessoires';

  @override
  String get baggageCategoryOther => 'Autre';

  @override
  String get baggageDeleteTitle => 'Supprimer l\'élément';

  @override
  String get baggageDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cet élément ?';

  @override
  String get baggageItemAdded => 'Élément ajouté';

  @override
  String get baggageItemDeleted => 'Élément supprimé';

  @override
  String get baggageItemAddedFromSuggestion =>
      'Élément ajouté depuis suggestion';

  @override
  String get baggageQuantityLabel => 'Qté';

  @override
  String get baggageCategoryLabel => 'Catégorie (optionnel)';

  @override
  String get baggageEmptyTitle => 'Aucun élément';

  @override
  String get baggageEmptySubtitle =>
      'Ajoutez des éléments à votre liste de bagages';

  @override
  String get baggageAddItemTitle => 'Ajouter un élément';

  @override
  String get accommodationsTitle => 'Hébergements';

  @override
  String get accommodationCheckInHelp => 'Date d\'arrivée';

  @override
  String get accommodationCheckOutHelp => 'Date de départ';

  @override
  String get accommodationAdded => 'Hébergement ajouté avec succès';

  @override
  String get accommodationDeleteTitle => 'Supprimer l\'hébergement';

  @override
  String get accommodationDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cet hébergement ?';

  @override
  String get accommodationDeleted => 'Hébergement supprimé';

  @override
  String get accommodationCheckInLabel => 'Arrivée';

  @override
  String get accommodationCheckOutLabel => 'Départ';

  @override
  String get accommodationEmptyTitle => 'Aucun hébergement';

  @override
  String get accommodationEmptySubtitle => 'Ajoutez vos hôtels et logements';

  @override
  String get accommodationAddTitle => 'Ajouter un hébergement';

  @override
  String get tripTravelers => 'Voyageurs';

  @override
  String get tripDaysRemaining => 'Jours restants';

  @override
  String get tripTravelDays => 'Jours de voyage';

  @override
  String get tripComplete => 'Terminer le voyage';

  @override
  String get tripDeleteTitle => 'Supprimer le voyage';

  @override
  String get tripDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer ce voyage ? Cette action est irréversible.';

  @override
  String get tripGiveReview => 'Donner un avis';

  @override
  String get tripsMyTrips => 'Mes voyages';

  @override
  String get tripsNewTrip => 'Nouveau voyage';

  @override
  String get tripStatusOngoing => 'En cours';

  @override
  String get tripStatusPlanned => 'Planifié';

  @override
  String get tripStatusCompleted => 'Terminé';

  @override
  String get tripsEmptyOngoing => 'Aucun voyage en cours';

  @override
  String get tripsEmptyPlanned => 'Aucun voyage planifié';

  @override
  String get tripsEmptyCompleted => 'Aucun voyage terminé';

  @override
  String get sharesTitle => 'Partages';

  @override
  String get sharesInviteButton => 'Inviter';

  @override
  String get sharesRevokeTitle => 'Révoquer l\'accès';

  @override
  String get sharesRevokeConfirm =>
      'Êtes-vous sûr de vouloir révoquer l\'accès de cet utilisateur ?';

  @override
  String get sharesRevokeButton => 'Révoquer';

  @override
  String get sharesEmpty => 'Aucun partage';

  @override
  String get sharesEmptySubtitle =>
      'Invitez des personnes à consulter votre voyage';

  @override
  String get tripCreated => 'Voyage créé !';

  @override
  String get aiResultsTitle => 'Résultats IA';

  @override
  String get feedbackTitle => 'Avis';

  @override
  String get feedbackGiveReview => 'Donner un avis';

  @override
  String get feedbackAllReviews => 'Tous les avis';

  @override
  String get feedbackGiveYourReview => 'Donner votre avis';

  @override
  String get feedbackOverallRating => 'Note globale';

  @override
  String get feedbackHighlights => 'Points forts';

  @override
  String get feedbackHighlightsHint => 'Qu\'avez-vous aimé ?';

  @override
  String get feedbackLowlights => 'Points faibles';

  @override
  String get feedbackLowlightsHint => 'Qu\'est-ce qui pourrait être amélioré ?';

  @override
  String get feedbackWouldRecommend => 'Recommanderiez-vous ce voyage ?';

  @override
  String get feedbackThanks => 'Merci pour votre avis !';

  @override
  String get feedbackSubmitButton => 'Envoyer mon avis';

  @override
  String get feedbackSent => 'Votre avis a été envoyé';

  @override
  String get feedbackRecommended => 'Recommandé : ';

  @override
  String get feedbackDiscoverNextTrip => 'Découvrir mon prochain voyage';

  @override
  String get feedbackDiscoverText =>
      'Découvrez votre prochain voyage idéal basé sur vos expériences.';

  @override
  String get postTripSuggestionTitle => 'Prochain voyage suggéré';

  @override
  String get postTripNextTrip => 'Votre prochain voyage';

  @override
  String get postTripBasedOnPreferences => 'Basé sur vos préférences';

  @override
  String get postTripProposedActivities => 'Activités proposées';

  @override
  String get postTripCreateTrip => 'Créer ce voyage';

  @override
  String get filterCabinBagIncluded => 'Bagage cabine inclus';

  @override
  String get filterCheckedBagIncluded => 'Bagage soute inclus';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get premiumFeatureAiUnlimited => 'Générations IA illimitées';

  @override
  String get premiumFeatureViewers => 'Jusqu\'à 10 viewers par trip';

  @override
  String get premiumFeatureOfflineNotifs => 'Notifications hors-ligne';

  @override
  String get premiumFeaturePostTrip => 'Suggestions post-voyage IA';

  @override
  String get premiumCtaButton => 'Passer à Premium - 9,99€/mois';

  @override
  String get profileConfigurePreferences => 'Configurez vos préférences';

  @override
  String profileStyleLabel(String style) {
    return 'Style : $style';
  }

  @override
  String profileBudgetLabel(String budget) {
    return 'Budget : $budget';
  }

  @override
  String profileCompanionsLabel(String companions) {
    return 'Compagnons : $companions';
  }

  @override
  String get errorNetwork =>
      'Erreur de connexion. Vérifiez votre connexion internet.';

  @override
  String get errorAuth => 'Identifiants incorrects ou session expirée.';

  @override
  String get errorForbidden => 'Accès refusé.';

  @override
  String get errorNotFound => 'Ressource non trouvée.';

  @override
  String get errorValidation => 'Requête invalide.';

  @override
  String get errorQuota => 'Limite atteinte. Passez à Premium pour continuer.';

  @override
  String get errorStaleContext =>
      'Le contexte a été mis à jour. Veuillez rafraîchir.';

  @override
  String get errorServer => 'Erreur serveur. Veuillez réessayer plus tard.';

  @override
  String get errorRateLimit => 'Trop de requêtes. Veuillez patienter.';

  @override
  String get errorCancelled => 'Opération annulée.';

  @override
  String get errorUnknown => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get errorSessionExpired => 'Session expirée';

  @override
  String get bookingLabel => 'Réservation';

  @override
  String get activitiesTitle => 'Activités';

  @override
  String get activitiesEmpty => 'Aucune activité';

  @override
  String get activitiesEmptySubtitle =>
      'Ajoutez des activités pour planifier votre voyage';

  @override
  String get activitiesSuggestionsTitle => 'Suggestions IA';

  @override
  String get activityFormNew => 'Nouvelle activité';

  @override
  String get activityFormEdit => 'Modifier l\'activité';

  @override
  String get activityTitleRequired => 'Le titre est requis';

  @override
  String get activityFormCreate => 'Créer';

  @override
  String get activityFormUpdate => 'Modifier';

  @override
  String get activityFormBooked => 'Réservé';

  @override
  String get feedbackYesLabel => 'Oui';

  @override
  String get feedbackNoLabel => 'Non';
}
