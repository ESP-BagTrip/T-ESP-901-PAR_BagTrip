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
  String get disconnect => 'Se déconnecter';

  @override
  String get continueButton => 'Continuer';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get personalInfoTitle => 'Informations personnelles';

  @override
  String get nameLabel => 'NOM';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get phoneLabel => 'TÉLÉPHONE';

  @override
  String get modifyButton => 'Modifier';

  @override
  String get editNameTitle => 'Modifier le nom';

  @override
  String get editPhoneTitle => 'Modifier le téléphone';

  @override
  String get saveButton => 'Enregistrer';

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
  String get noRecentBookings => 'Aucune réservation récente';

  @override
  String get bookingStatusCompleted => 'Terminé';

  @override
  String get bookingStatusConfirmed => 'Confirmé';

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
  String get personalizationProfileSectionTitle =>
      'Personnalisation de l\'expérience';

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
  String get personalizationTravelStylePlanned => 'Tout planifié';

  @override
  String get personalizationTravelStyleFlexible => 'Flexible';

  @override
  String get personalizationTravelStyleSpontaneous => 'Spontané';

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
  String get planifierGreeting => 'Bonjour';

  @override
  String get destinationPlaceholder => 'Paris, Tokyo, New York...';

  @override
  String get recapDateChoose => 'Choisir';

  @override
  String get recapDateSelectHint => 'Sélectionner';

  @override
  String get summarySectionWhereStay => 'OÙ LOGER';

  @override
  String get summarySectionFlight => 'VOL';

  @override
  String get summarySectionYourJourney => 'VOTRE VOYAGE';

  @override
  String get summarySectionEssentials => 'ESSENTIELS';

  @override
  String get summaryDayPrefix => 'J';

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
  String get activityTitle => 'Titre';

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
  String get activityDeleteTitle => 'Supprimer l\'activité';

  @override
  String get activityDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette activité ?';

  @override
  String get activityEndTimeBeforeStartTime =>
      'L\'heure de fin doit être après l\'heure de début';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryOther => 'Autre';

  @override
  String get budgetItems => 'Budget';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get editExpense => 'Modifier la dépense';

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
  String get expenseLabelRequired => 'Libellé requis';

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
  String get backButton => 'Retour';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabActivity => 'Activité';

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
  String get notificationsJustNow => 'À l\'instant';

  @override
  String notificationsMinutesAgo(int count) {
    return 'Il y a $count min';
  }

  @override
  String notificationsHoursAgo(int count) {
    return 'Il y a ${count}h';
  }

  @override
  String notificationsShortDaysAgo(int count) {
    return 'Il y a ${count}j';
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
  String get baggageQuantityLabel => 'Qté';

  @override
  String get baggageCategoryLabel => 'Catégorie (optionnel)';

  @override
  String get baggageAddItemTitle => 'Ajouter un élément';

  @override
  String baggagePackedCount(int packed, int total) {
    return '$packed sur $total emballés';
  }

  @override
  String get baggageSuggestionsTitle => 'Suggestions pour vous';

  @override
  String get baggageToPack => 'À emballer';

  @override
  String get baggagePacked => 'Emballés';

  @override
  String get baggageSwipeToPack => 'Glisser pour emballer';

  @override
  String get baggageUnpack => 'Déballer';

  @override
  String get baggageEditItemTitle => 'Modifier l\'élément';

  @override
  String get baggageItemName => 'Nom de l\'élément';

  @override
  String get fieldRequired => 'Ce champ est requis';

  @override
  String get accommodationsTitle => 'Hébergements';

  @override
  String get accommodationCheckInLabel => 'Arrivée';

  @override
  String get accommodationCheckOutLabel => 'Départ';

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
  String get tripStatusOngoing => 'En cours';

  @override
  String get tripStatusPlanned => 'À venir';

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
  String get sharesRevokeButton => 'Révoquer';

  @override
  String get sharesEmpty => 'Aucun partage';

  @override
  String get sharesEmptySubtitle =>
      'Invitez des personnes à consulter votre voyage';

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
  String postTripSuggestionDuration(int days) {
    return '$days jours';
  }

  @override
  String postTripSuggestionBudget(String amount) {
    return '$amount€';
  }

  @override
  String get feedbackNoReviews => 'Aucun avis';

  @override
  String feedbackHighlightsPrefix(String highlights) {
    return 'Points forts : $highlights';
  }

  @override
  String feedbackLowlightsPrefix(String lowlights) {
    return 'À améliorer : $lowlights';
  }

  @override
  String get feedbackRecommends => 'Recommande';

  @override
  String get feedbackNotRecommends => 'Ne recommande pas';

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
  String get premiumPaywallTitle => 'Passez à Premium';

  @override
  String tripDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String tripShareInvitedOnDate(String date) {
    return 'Invité le $date';
  }

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
  String get bookingLabel => 'Réservation';

  @override
  String get activitiesTitle => 'Activités';

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

  @override
  String get offlineMode => 'Vous êtes hors ligne. Données en cache affichées.';

  @override
  String get subscriptionVerifying => 'Vérification de votre abonnement...';

  @override
  String get subscriptionWelcomePremium => 'Bienvenue en Premium !';

  @override
  String get subscriptionPending => 'Abonnement en attente';

  @override
  String get subscriptionSuccessMessage =>
      'Vous avez désormais accès à toutes les fonctionnalités premium. Profitez des générations IA illimitées et plus encore !';

  @override
  String get subscriptionPendingMessage =>
      'Votre paiement est en cours de traitement. L\'activation peut prendre un instant.';

  @override
  String get subscriptionCancelTitle => 'Paiement non complété';

  @override
  String get subscriptionCancelMessage =>
      'Votre paiement d\'abonnement n\'a pas été finalisé. Vous pouvez réessayer ou retourner à votre profil.';

  @override
  String get subscriptionBackToProfile => 'Retour au profil';

  @override
  String get paymentSuccessTitle => 'Paiement confirmé !';

  @override
  String get paymentSuccessMessage =>
      'Votre réservation de vol a été confirmée. Vous pouvez la consulter dans vos voyages.';

  @override
  String get paymentBackToTrips => 'Retour à mes voyages';

  @override
  String get paymentCancelledTitle => 'Paiement annulé';

  @override
  String get paymentCancelledMessage =>
      'Votre paiement a été annulé. Aucun montant n\'a été débité.';

  @override
  String get payment3dsReturnTitle => 'Paiement en cours';

  @override
  String get payment3dsReturnMessage =>
      'Votre paiement est en cours de traitement. Vous recevrez une confirmation sous peu.';

  @override
  String nextTripCountdown(int days) {
    return 'Dans $days jours';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get personalInfoPageTitle => 'Informations personnelles';

  @override
  String get travelPreferencesTitle => 'Préférences de voyage';

  @override
  String homeGreeting(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String homeGreetingMorning(String name) {
    return 'Bonjour,\n$name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Bon après-midi,\n$name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Bonsoir,\n$name';
  }

  @override
  String get homeWelcomeTitle => 'Prêt à voyager ?';

  @override
  String get homeSubtitleEmpty => 'Quelle sera ta prochaine destination ?';

  @override
  String get homeSubtitleOneTrip => '1 voyage planifié';

  @override
  String homeSubtitleTrips(int count) {
    return '$count voyages planifiés';
  }

  @override
  String get homeCreateFirstTrip => 'Créer mon premier voyage';

  @override
  String get planTripCta => 'Planifier un voyage';

  @override
  String get homeCtaAiOrManual => 'IA ou manuel';

  @override
  String get homeCtaStartPlanning => 'Commencer';

  @override
  String get inspireMe => 'Inspire-moi';

  @override
  String get datesLabel => 'DATES';

  @override
  String get datesChooseDatePlaceholder => 'Choisir une date';

  @override
  String tripNightsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuits',
      one: '1 nuit',
    );
    return '$_temp0';
  }

  @override
  String get days => 'jours';

  @override
  String get tripCreatedSuccess => 'Voyage créé avec succès !';

  @override
  String get stepDestination => 'Où ?';

  @override
  String get stepTravelers => 'Qui ?';

  @override
  String get stepReview => 'Résumé';

  @override
  String get addFirstAccommodation => 'Ajouter un hébergement';

  @override
  String get addFirstActivity => 'Ajouter une activité';

  @override
  String get addFirstBaggage => 'Préparer vos bagages';

  @override
  String get addFirstBudget => 'Suivre vos dépenses';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get transportsTitle => 'Transports';

  @override
  String get addFirstTransport => 'Ajoutez votre vol';

  @override
  String get addFlight => 'Ajouter un vol';

  @override
  String get addFlightSubtitle =>
      'Entrez votre numéro de vol pour obtenir les infos en direct';

  @override
  String get searchFlightOption => 'Rechercher un vol';

  @override
  String get searchFlightOptionSubtitle => 'Trouvez et comparez des vols';

  @override
  String get addManuallyOption => 'Ajouter manuellement';

  @override
  String get addManuallyOptionSubtitle => 'Saisissez les détails du vol';

  @override
  String get mainFlightsSection => 'Vols principaux';

  @override
  String get internalFlightsSection => 'Vols internes';

  @override
  String get flightNumberLabel => 'Numéro de vol';

  @override
  String get flightNumberRequired => 'Le numéro de vol est requis';

  @override
  String get airlineLabel => 'Compagnie aérienne';

  @override
  String get departureAirportLabel => 'Départ';

  @override
  String get arrivalAirportLabel => 'Arrivée';

  @override
  String get departureDateLabel => 'Date de départ';

  @override
  String get arrivalDateLabel => 'Date d\'arrivée';

  @override
  String get priceLabel => 'Prix';

  @override
  String get notesLabel => 'Notes';

  @override
  String get mainFlightType => 'Principal';

  @override
  String get internalFlightType => 'Interne';

  @override
  String get editButton => 'Modifier';

  @override
  String get activityToValidate => 'À vérifier';

  @override
  String get activityValidated => 'Vérifié';

  @override
  String get activityDisclaimerSubtitle =>
      'Suggestions IA — vérifiez disponibilité et tarifs';

  @override
  String get activityValidateConfirmTitle => 'Vérifier cette activité ?';

  @override
  String get activityValidateConfirmMessage =>
      'Vous pouvez ajuster le coût estimé si besoin.';

  @override
  String get activityValidateCostLabel => 'Coût réel (optionnel)';

  @override
  String get activityValidateConfirm => 'Confirmer';

  @override
  String get accommodationSearchHotels => 'Rechercher un hôtel';

  @override
  String get accommodationSearchHotelsSubtitle =>
      'Trouver et comparer les prix';

  @override
  String get accommodationAddManually => 'Ajouter manuellement';

  @override
  String get accommodationAddManuallySubtitle =>
      'Airbnb, auberge, hôtel, camping...';

  @override
  String get accommodationAiSuggestTitle => 'Recommandations IA';

  @override
  String get accommodationEstimatedPrice => 'Prix estimé';

  @override
  String get accommodationNights => 'nuit(s)';

  @override
  String get accommodationTotal => 'Total';

  @override
  String get accommodationSearchInArea => 'Rechercher dans le quartier';

  @override
  String get accommodationTypeHotel => 'Hôtel';

  @override
  String get accommodationTypeAirbnb => 'Airbnb';

  @override
  String get accommodationTypeHostel => 'Auberge';

  @override
  String get accommodationTypeCamping => 'Camping';

  @override
  String get accommodationTypeGuesthouse => 'Maison d\'hôtes';

  @override
  String get accommodationTypeResort => 'Resort';

  @override
  String get accommodationTypeOther => 'Autre';

  @override
  String get accommodationPricePerNight => 'Prix/nuit';

  @override
  String get accommodationAiDisclaimer =>
      'Suggestions IA — vérifiez disponibilité et tarifs';

  @override
  String get budgetConfirmed => 'Confirmé';

  @override
  String get budgetForecasted => 'Prévisionnel';

  @override
  String get budgetEstimateButton => 'Estimer mon budget';

  @override
  String get budgetEstimateTitle => 'Estimation du budget';

  @override
  String get budgetEstimateAccept => 'Accepter';

  @override
  String get budgetEstimateModify => 'Modifier';

  @override
  String get budgetAccommodationPerNight => 'Hébergement / nuit';

  @override
  String get budgetMealsPerDay => 'Repas / jour / personne';

  @override
  String get budgetLocalTransport => 'Transport local / jour';

  @override
  String get budgetActivitiesTotal => 'Total activités';

  @override
  String budgetTotalRange(String min, String max, String currency) {
    return '$min – $max $currency';
  }

  @override
  String get statusPending => 'À valider';

  @override
  String get statusConfirmed => 'Confirmé';

  @override
  String get statusForecasted => 'Prévisionnel';

  @override
  String get statusActive => 'En cours';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get emptyTransportsTitle => 'Où volez-vous ?';

  @override
  String get emptyTransportsSubtitle =>
      'Ajoutez vos vols pour organiser votre voyage';

  @override
  String get emptyAccommodationsTitle => 'Où dormirez-vous ?';

  @override
  String get emptyAccommodationsSubtitle => 'Ajoutez vos hôtels et logements';

  @override
  String get emptyActivitiesTitle => 'Que découvrirez-vous ?';

  @override
  String get emptyActivitiesSubtitle =>
      'Ajoutez des activités pour planifier votre voyage';

  @override
  String get emptyBaggageTitle => 'Que faut-il emporter ?';

  @override
  String get emptyBaggageSubtitle =>
      'Ajoutez des éléments à votre liste de bagages';

  @override
  String get emptyBudgetTitle => 'Suivez vos dépenses';

  @override
  String get emptyBudgetSubtitle =>
      'Suivez vos dépenses et planifiez votre budget voyage';

  @override
  String get mapTitle => 'Carte';

  @override
  String get mapComingSoonSubtitle =>
      'Votre voyage sur une carte. Bientôt disponible.';

  @override
  String get mapComingSoonShort => 'Carte bientôt';

  @override
  String get datesModeExact => 'Dates exactes';

  @override
  String get datesModeMonth => 'Mois';

  @override
  String get datesModeFlexible => 'Flexible';

  @override
  String get datesFlexibleWeekend => 'Week-end';

  @override
  String get datesFlexibleWeek => '1 semaine';

  @override
  String get datesFlexibleTwoWeeks => '2 semaines';

  @override
  String get datesFlexibleThreeWeeks => '3 semaines';

  @override
  String get datesFlexibleWeekendDays => '2-3 jours';

  @override
  String get datesFlexibleWeekDays => '7 jours';

  @override
  String get datesFlexibleTwoWeeksDays => '14 jours';

  @override
  String get datesFlexibleThreeWeeksDays => '21 jours';

  @override
  String get planTripStepDates => 'Quand partez-vous ?';

  @override
  String get travelersLabel => 'VOYAGEURS';

  @override
  String travelerCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voyageurs',
      one: '1 voyageur',
    );
    return '$_temp0';
  }

  @override
  String get travelerTypeAdults => 'Adultes';

  @override
  String get travelerTypeChildren => 'Enfants';

  @override
  String get travelerTypeBabies => 'Bébés';

  @override
  String get travelerAgeAdultsSubtitle => '13 ans et plus';

  @override
  String get travelerAgeChildrenSubtitle => '3 à 12 ans';

  @override
  String get travelerAgeBabiesSubtitle => '0 à 2 ans';

  @override
  String travelerSegmentAdult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adultes',
      one: '1 adulte',
    );
    return '$_temp0';
  }

  @override
  String travelerSegmentChild(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enfants',
      one: '1 enfant',
    );
    return '$_temp0';
  }

  @override
  String travelerSegmentBaby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bébés',
      one: '1 bébé',
    );
    return '$_temp0';
  }

  @override
  String planTripDurationDaysNights(int days, int nights) {
    return '$days jours · $nights nuits';
  }

  @override
  String get budgetLabel => 'BUDGET';

  @override
  String get budgetPresetBackpacker => 'Routard';

  @override
  String get budgetPresetBackpackerDesc => '30–60 €/jour';

  @override
  String get budgetPresetComfortable => 'Confortable';

  @override
  String get budgetPresetComfortableDesc => '80–150 €/jour';

  @override
  String get budgetPresetPremium => 'Premium';

  @override
  String get budgetPresetPremiumDesc => '200–400 €/jour';

  @override
  String get budgetPresetNoLimit => 'Sans limite';

  @override
  String get budgetPresetNoLimitDesc => '400+ €/jour';

  @override
  String get budgetEstimationLabel => 'TOTAL ESTIMÉ';

  @override
  String get budgetSkipLabel => 'Je verrai plus tard';

  @override
  String get destinationSectionLabel => 'DESTINATION';

  @override
  String get destinationPopularSectionLabel => 'POPULAIRES EN CE MOMENT';

  @override
  String get destinationOrSeparator => 'OU';

  @override
  String get destinationNoResults => 'Aucun résultat trouvé';

  @override
  String get destinationAiLoading => 'Notre IA cherche pour vous...';

  @override
  String get stepAiProposals => 'Vos destinations';

  @override
  String get chooseThisDestination => 'Choisir cette destination';

  @override
  String get swipeToDiscover => 'Glissez pour découvrir →';

  @override
  String get aiProposalsEmpty => 'Aucune suggestion disponible';

  @override
  String get aiProposalsEmptySubtitle => 'Retournez en arrière et réessayez';

  @override
  String get aiBadgeLabel => 'IA';

  @override
  String get stepGeneration => 'Génération...';

  @override
  String get generationTitle => 'GÉNÉRATION IA';

  @override
  String get generationStepDestinations => 'Destinations';

  @override
  String get generationStepActivities => 'Activités';

  @override
  String get generationStepAccommodations => 'Hébergements';

  @override
  String get generationStepBaggage => 'Bagages';

  @override
  String get generationStepBudget => 'Budget';

  @override
  String get generationErrorTitle => 'Échec de la génération';

  @override
  String get generationErrorSubtitle =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get generationTimeoutTitle => 'Temps dépassé';

  @override
  String get generationTimeoutSubtitle =>
      'La génération prend plus de temps que prévu. Veuillez réessayer.';

  @override
  String generationProgressLabel(int percent) {
    return '$percent%';
  }

  @override
  String get reviewCreateTrip => 'Créer mon voyage';

  @override
  String get reviewSeeOtherDestinations => 'Voir d\'autres destinations';

  @override
  String get reviewSectionBudget => 'RÉPARTITION DU BUDGET';

  @override
  String get reviewBudgetFlights => 'Vols';

  @override
  String get reviewBudgetAccommodation => 'Hébergement';

  @override
  String get reviewBudgetMeals => 'Repas';

  @override
  String get reviewBudgetTransport => 'Transport';

  @override
  String get reviewBudgetActivities => 'Activités';

  @override
  String get reviewBudgetOther => 'Autre';

  @override
  String get reviewBudgetTotal => 'Total';

  @override
  String get reviewSourceVerified => 'Vérifié';

  @override
  String get reviewSourceEstimated => 'Estimé';

  @override
  String reviewPriceEur(String amount) {
    return '$amount EUR';
  }

  @override
  String get reviewHighlightsLabel => 'TEMPS FORTS';

  @override
  String get reviewSectionDates => 'DATES';

  @override
  String get reviewDatesSuggested => 'Dates suggérées — appuyez pour ajuster';

  @override
  String reviewEssentialReason(String reason) {
    return 'Pourquoi : $reason';
  }

  @override
  String get reviewNoActivities => 'Aucune activité prévue';

  @override
  String homeActiveTripTitle(String destination) {
    return 'Votre voyage à $destination';
  }

  @override
  String homeActiveTripDay(int current, int total) {
    return 'Jour $current sur $total';
  }

  @override
  String get homeTodayActivities => 'Programme du jour';

  @override
  String get homeNoActivitiesToday => 'Aucune activité prévue aujourd\'hui';

  @override
  String get tripCardNoDestination => 'Pas de destination';

  @override
  String get tripCardNoTitle => 'Voyage sans titre';

  @override
  String get activeTripsAllDay => 'Toute la journée';

  @override
  String get activeTripsTomorrow => 'Demain';

  @override
  String activeTripsTomorrowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activités',
      one: '1 activité',
    );
    return '$_temp0';
  }

  @override
  String get activeTripsQuickActions => 'Actions rapides';

  @override
  String get completionDates => 'Dates';

  @override
  String get completionFlights => 'Vols';

  @override
  String get completionAccommodation => 'Hôtels';

  @override
  String get completionActivities => 'Activités';

  @override
  String get completionBaggage => 'Bagages';

  @override
  String get completionBudget => 'Budget';

  @override
  String get tripDetailQuickFlights => 'Vols';

  @override
  String get tripDetailQuickActivities => 'Activités';

  @override
  String get tripDetailQuickAddFlight => 'Ajouter vol';

  @override
  String get tripDetailQuickAddHotel => 'Ajouter hôtel';

  @override
  String get tripDetailQuickAddActivity => 'Ajouter activité';

  @override
  String get tripDetailQuickExpense => 'Dépense';

  @override
  String get tripDetailQuickBaggage => 'Bagages';

  @override
  String get tripDetailQuickMemories => 'Souvenirs';

  @override
  String get timelineSectionTitle => 'Itinéraire';

  @override
  String get timelineMorning => 'Matin';

  @override
  String get timelineAfternoon => 'Après-midi';

  @override
  String get timelineEvening => 'Soirée';

  @override
  String get timelineEmptyDayTitle => 'Aucune activité';

  @override
  String get timelineEmptyDaySubtitle =>
      'Ajoutez-en ou demandez à l\'IA de vous suggérer des idées';

  @override
  String get timelineValidate => 'Valider';

  @override
  String get timelineReject => 'Rejeter';

  @override
  String get flightStatusConfirmed => 'Confirmé';

  @override
  String get flightStatusPending => 'En attente';

  @override
  String get flightsSectionEmptyTitle => 'Où allez-vous ?';

  @override
  String get flightsSectionEmptySubtitle =>
      'Ajoutez vos vols pour organiser votre voyage';

  @override
  String flightsSectionSeeAll(int count) {
    return 'Voir tous les vols ($count)';
  }

  @override
  String get flightsSectionTitle => 'Vols';

  @override
  String accommodationSectionSeeAll(int count) {
    return 'Voir tous les hébergements ($count)';
  }

  @override
  String get accommodationStatusConfirmed => 'Confirmé';

  @override
  String get accommodationStatusPending => 'En attente';

  @override
  String baggageSectionSeeAll(int count) {
    return 'Voir tous les éléments ($count)';
  }

  @override
  String get baggageSectionAddItem => 'Ajouter un élément';

  @override
  String get baggageSectionAddItemSubtitle => 'Créez votre liste';

  @override
  String get baggageSectionAiSuggest => 'Suggestions IA';

  @override
  String get baggageSectionAiSuggestSubtitle => 'Laissez l\'IA vous aider';

  @override
  String get budgetEstimateOptionSubtitle =>
      'Laissez l\'IA vous suggerer un budget';

  @override
  String get budgetAddExpenseSubtitle => 'Suivez une depense prevue ou reelle';

  @override
  String get budgetManageAll => 'Gerer le budget';

  @override
  String get budgetCategoryBreakdown => 'Repartition';

  @override
  String get sharingSectionTitle => 'Partage';

  @override
  String get sharingSectionEmptyTitle => 'Partagez votre voyage';

  @override
  String get sharingSectionEmptySubtitle =>
      'Invitez vos proches a suivre votre voyage';

  @override
  String get sharingSectionInvite => 'Inviter quelqu\'un';

  @override
  String get sharingSectionInviteSubtitle =>
      'Partagez votre voyage avec d\'autres';

  @override
  String sharingSectionSeeAll(int count) {
    return 'Voir tous les membres ($count)';
  }

  @override
  String get sharingSectionOwner => 'Proprietaire';

  @override
  String get sharingSectionViewer => 'Lecteur';

  @override
  String get sharingSectionYou => 'Vous';

  @override
  String timelineInMinutes(int minutes) {
    return 'Dans $minutes min';
  }

  @override
  String get timelineNow => 'Maintenant';

  @override
  String get timelineInProgress => 'En cours';

  @override
  String timelineRemainingMinutes(int minutes) {
    return '$minutes min restantes';
  }

  @override
  String get timelineNavigate => 'Naviguer';

  @override
  String get timelineChooseMapApp => 'Choisir l\'application';

  @override
  String get timelineAppleMaps => 'Apple Plans';

  @override
  String get timelineGoogleMaps => 'Google Maps';

  @override
  String get activeTripsTomorrowLastDay => 'Dernier jour de voyage';

  @override
  String activeTripsTomorrowShowAll(int count) {
    return 'Voir tout ($count)';
  }

  @override
  String get activeTripsTomorrowCollapse => 'Voir moins';

  @override
  String get qaSchedule => 'Programme';

  @override
  String get qaWeather => 'Meteo';

  @override
  String get qaCheckOut => 'Check-out';

  @override
  String get qaNavigate => 'Naviguer';

  @override
  String get qaExpense => 'Depense';

  @override
  String get qaPhoto => 'Photo';

  @override
  String get qaNextActivity => 'Prochaine';

  @override
  String get qaAiSuggestion => 'Idee IA';

  @override
  String get qaMap => 'Plan';

  @override
  String get qaTodayExpenses => 'Aujourd\'hui';

  @override
  String get qaTomorrow => 'Demain';

  @override
  String get qaBudget => 'Budget';

  @override
  String get qaQuickExpenseTitle => 'Depense rapide';

  @override
  String get qaQuickExpenseNote => 'Note (optionnel)';

  @override
  String get qaQuickExpenseAmount => 'Montant';

  @override
  String get qaQuickExpenseAmountRequired => 'Montant requis';

  @override
  String get qaQuickExpenseInvalidAmount => 'Montant invalide';

  @override
  String get qaCategoryFood => 'Repas';

  @override
  String get qaCategoryTransport => 'Transport';

  @override
  String get qaCategoryActivity => 'Activite';

  @override
  String get qaCategoryOther => 'Autre';

  @override
  String get postTripDetectionTitle => 'Voyage terminé !';

  @override
  String postTripDetectionMessage(String destination) {
    return 'Votre voyage à $destination est terminé. Voulez-vous le marquer comme complété ?';
  }

  @override
  String get postTripDetectionConfirm => 'Oui, terminer';

  @override
  String get postTripDetectionRemindLater => 'Me rappeler plus tard';

  @override
  String get postTripSouvenirsTitle => 'Souvenirs';

  @override
  String postTripDaysCount(int count) {
    return '$count jours d\'aventure';
  }

  @override
  String postTripActivitiesCompleted(int completed, int total) {
    return '$completed sur $total activités';
  }

  @override
  String postTripBudgetSpent(String amount) {
    return '$amount dépensés';
  }

  @override
  String postTripCategoriesExplored(int count) {
    return '$count catégories explorées';
  }

  @override
  String get postTripGiveReview => 'Partagez votre expérience';

  @override
  String get postTripPlanNext => 'Planifier votre prochain voyage';

  @override
  String get feedbackAiRatingLabel => 'Notez l\'expérience de planification IA';

  @override
  String get editTripTitle => 'Modifier le nom du voyage';

  @override
  String get editTripDates => 'Dates du voyage';

  @override
  String get editTripStartDate => 'Date de début';

  @override
  String get editTripEndDate => 'Date de fin';

  @override
  String get editTripTravelers => 'Voyageurs';

  @override
  String get activitiesOutOfRangeTitle => 'Activités hors période';

  @override
  String activitiesOutOfRangeMessage(int count) {
    return '$count activités sont hors de la nouvelle période';
  }

  @override
  String get cannotFinalizeTitle => 'Impossible de finaliser';

  @override
  String get cannotFinalizeMessage => 'Ajoutez une destination et des dates';

  @override
  String get finalizeMissingDestination => 'Destination manquante';

  @override
  String get finalizeMissingDates => 'Dates manquantes';

  @override
  String get routeSectionLabel => 'Itinéraire';

  @override
  String get scheduleSectionLabel => 'Horaires';

  @override
  String get detailsSectionLabel => 'Détails';

  @override
  String get airportsMustDiffer =>
      'Les aéroports de départ et d\'arrivée doivent être différents';

  @override
  String get arrivalMustBeAfterDeparture =>
      'L\'arrivée doit être après le départ';

  @override
  String get accommodationEditTitle => 'Modifier l\'hébergement';

  @override
  String get accommodationSaveButton => 'Enregistrer';

  @override
  String get accommodationAddressLabel => 'Adresse';

  @override
  String get accommodationReferenceLabel => 'Référence de réservation';

  @override
  String get accommodationCheckOutBeforeCheckIn =>
      'Le check-out doit être après le check-in';

  @override
  String get accommodationCheckInTimeLabel => 'Heure d\'arrivée';

  @override
  String get accommodationCheckOutTimeLabel => 'Heure de départ';

  @override
  String get accommodationSelectHotel => 'Sélectionner';

  @override
  String get accommodationPerNight => '/nuit';

  @override
  String get accommodationNoResults => 'Aucun hôtel trouvé';

  @override
  String get baggageAllPacked => 'Tout est prêt !';

  @override
  String get baggageAllPackedSubtitle => 'Vous êtes prêt pour votre voyage !';

  @override
  String get baggageSwipeToDelete => 'Supprimer';

  @override
  String activityBatchCount(int count) {
    return '$count à valider';
  }

  @override
  String get activityValidateAll => 'Tout valider';

  @override
  String get activityReviewOneByOne => 'Revoir un par un';

  @override
  String get activityBatchValidated => 'Toutes les activités validées !';

  @override
  String get categoryCulture => 'Culture';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryFoodDrink => 'Gastronomie';

  @override
  String get categorySport => 'Sport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryNightlife => 'Vie nocturne';

  @override
  String get categoryRelaxation => 'Détente';

  @override
  String get categoryOtherActivity => 'Autre';

  @override
  String activityMovedToDay(int day) {
    return 'Activité déplacée au jour $day';
  }

  @override
  String get timelineGetSuggestions => 'Obtenir des suggestions IA';

  @override
  String get timelineSuggestionsForDay => 'Suggestions pour cette journée';

  @override
  String get timelineAddSuggestion => 'Ajouter à l\'itinéraire';

  @override
  String get addActivityManually => 'Ajouter manuellement';

  @override
  String get shareInviteTitle => 'Inviter au voyage';

  @override
  String get shareInviteEmailLabel => 'Adresse email';

  @override
  String get shareInviteEmailHint => 'utilisateur@exemple.com';

  @override
  String get shareInviteEmailRequired => 'L\'email est requis';

  @override
  String get shareInviteEmailInvalid => 'Format d\'email invalide';

  @override
  String get shareInviteMessageLabel => 'Message (optionnel)';

  @override
  String get shareInviteMessageHint => 'Ajouter un message personnel...';

  @override
  String get shareInviteSendButton => 'Envoyer l\'invitation';

  @override
  String get shareRoleViewer => 'Lecteur';

  @override
  String get shareRoleEditor => 'Éditeur';

  @override
  String get shareInvitePendingMessage =>
      'Cette personne n\'est pas encore inscrite. Elle aura accès en s\'inscrivant.';

  @override
  String get shareInviteLinkCopied => 'Lien d\'invitation copié';

  @override
  String get shareErrorUserNotFound =>
      'Cette personne doit d\'abord créer un compte';

  @override
  String get shareErrorAlreadyShared => 'Déjà partagé avec cette personne';

  @override
  String get shareErrorSelfShare =>
      'Vous ne pouvez pas partager un voyage avec vous-même';

  @override
  String get shareRevokeConfirmTitle => 'Retirer l\'accès';

  @override
  String shareRevokeConfirmMessage(String name) {
    return 'Retirer l\'accès de $name ?';
  }

  @override
  String get viewerBadgeReadOnly => 'Lecture seule';

  @override
  String get shareInviteSuccess => 'Invitation envoyée';

  @override
  String get filterTitle => 'Filtres';

  @override
  String get filterPrice => 'Prix';

  @override
  String get filterPriceLowest => 'Prix le plus bas';

  @override
  String get filterPriceHighest => 'Prix le plus haut';

  @override
  String get filterAirline => 'Compagnie aérienne';

  @override
  String get filterNoAirlines => 'Aucune compagnie disponible';

  @override
  String get filterAllAirlines => 'Toutes';

  @override
  String get filterBaggage => 'Bagages';

  @override
  String get filterDepartureTime => 'Heure de départ';

  @override
  String get filterBefore => 'Avant';

  @override
  String get filterAfter => 'Après';

  @override
  String get filterApply => 'Appliquer';

  @override
  String get doneButton => 'Terminé';

  @override
  String get contextMenuView => 'Voir';

  @override
  String get contextMenuShare => 'Partager';

  @override
  String get contextMenuArchive => 'Archiver';

  @override
  String get contextMenuEdit => 'Modifier';

  @override
  String get contextMenuValidate => 'Valider';

  @override
  String get contextMenuDelete => 'Supprimer';

  @override
  String get contextMenuMoveToDay => 'Déplacer vers un autre jour';

  @override
  String contextMenuDayLabel(int day) {
    return 'Jour $day';
  }

  @override
  String tripCardSemanticLabel(
    String destination,
    String dateRange,
    String status,
  ) {
    return '$destination, $dateRange, $status';
  }

  @override
  String tripCoverImageLabel(String destination) {
    return 'Photo de couverture de $destination';
  }

  @override
  String activityCardSemanticLabel(
    String title,
    String time,
    String location,
    String status,
  ) {
    return '$title, $time, $location, $status';
  }

  @override
  String timelineActivitySemanticLabel(
    String title,
    String time,
    String location,
  ) {
    return '$title, $time, $location';
  }

  @override
  String get addTripTooltip => 'Ajouter un voyage';

  @override
  String get addActivityTooltip => 'Ajouter une activite';

  @override
  String get addAccommodationTooltip => 'Ajouter un hebergement';

  @override
  String get addTransportTooltip => 'Ajouter un transport';

  @override
  String get addExpenseTooltip => 'Ajouter une depense';

  @override
  String get addBaggageItemTooltip => 'Ajouter un element';

  @override
  String get shareTooltip => 'Partager';

  @override
  String get backTooltip => 'Retour';

  @override
  String get deleteFlightTooltip => 'Supprimer le vol';

  @override
  String get editFlight => 'Modifier le vol';

  @override
  String get editFlightTooltip => 'Modifier ce vol';

  @override
  String get multiDestResults => 'Résultats par segment';

  @override
  String segmentLabel(int index) {
    return 'Segment $index';
  }

  @override
  String get deleteAccommodationTooltip => 'Supprimer l\'hebergement';

  @override
  String get removeAccessTooltip => 'Retirer l\'acces';

  @override
  String get inviteTooltip => 'Inviter';

  @override
  String get acceptSuggestionTooltip => 'Accepter la suggestion';

  @override
  String get dismissSuggestionTooltip => 'Ignorer la suggestion';

  @override
  String get decreaseQuantityTooltip => 'Diminuer la quantite';

  @override
  String get increaseQuantityTooltip => 'Augmenter la quantite';

  @override
  String starRatingTooltip(int current, int total) {
    return '$current sur $total etoiles';
  }

  @override
  String tabActivityWithBadge(int count) {
    return 'Activite, $count notifications';
  }

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.';

  @override
  String get forgotPasswordSendButton => 'Envoyer le lien';

  @override
  String get forgotPasswordSuccess =>
      'Si cette adresse existe, un lien de réinitialisation a été envoyé. Vérifiez votre boîte de réception.';

  @override
  String get deleteAccountButton => 'Supprimer mon compte';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cela supprimera définitivement votre compte et toutes les données associées. Cette action est irréversible.';

  @override
  String get deleteAccountConfirmAction => 'Supprimer définitivement';

  @override
  String get bookFlight => 'Réserver ce vol';

  @override
  String get weatherSheetTitle => 'Météo';

  @override
  String get weatherSheetTemperature => 'Température';

  @override
  String get weatherSheetRainProbability => 'Probabilité de pluie';

  @override
  String get weatherSheetUnavailable => 'Données météo indisponibles';

  @override
  String get photoLaunchFailed => 'Impossible d\'ouvrir l\'appareil photo';

  @override
  String get mapLocationsTitle => 'Lieux du voyage';

  @override
  String get mapNoLocations => 'Aucun lieu ajouté';

  @override
  String get mapDestination => 'Destination';

  @override
  String get mapActivities => 'Activités';

  @override
  String get mapAccommodations => 'Hébergements';

  @override
  String get notFoundTitle => 'Page introuvable';

  @override
  String get notFoundSubtitle =>
      'La page que vous recherchez n\'existe pas ou a été déplacée.';

  @override
  String get notFoundCta => 'Retour à l\'accueil';
}
