import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @dateFormatHint.
  ///
  /// In fr, this message translates to:
  /// **'jj/mm/aaaa'**
  String get dateFormatHint;

  /// No description provided for @travelClassTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classe de voyage'**
  String get travelClassTitle;

  /// No description provided for @passengersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passagers'**
  String get passengersTitle;

  /// No description provided for @searchFlightButton.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher votre vol'**
  String get searchFlightButton;

  /// No description provided for @errorAddAtLeastOneFlight.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins un vol'**
  String get errorAddAtLeastOneFlight;

  /// No description provided for @errorFillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs obligatoires'**
  String get errorFillAllFields;

  /// No description provided for @travelClassEconomy.
  ///
  /// In fr, this message translates to:
  /// **'Économique'**
  String get travelClassEconomy;

  /// No description provided for @travelClassPremiumEconomy.
  ///
  /// In fr, this message translates to:
  /// **'Premium Éco'**
  String get travelClassPremiumEconomy;

  /// No description provided for @travelClassBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Affaires'**
  String get travelClassBusiness;

  /// No description provided for @travelClassFirst.
  ///
  /// In fr, this message translates to:
  /// **'Première'**
  String get travelClassFirst;

  /// No description provided for @tripTypeRoundTrip.
  ///
  /// In fr, this message translates to:
  /// **'Aller-retour'**
  String get tripTypeRoundTrip;

  /// No description provided for @tripTypeOneWay.
  ///
  /// In fr, this message translates to:
  /// **'Aller simple'**
  String get tripTypeOneWay;

  /// No description provided for @tripTypeMultiCity.
  ///
  /// In fr, this message translates to:
  /// **'Multi-destinations'**
  String get tripTypeMultiCity;

  /// No description provided for @airportDepartureHint.
  ///
  /// In fr, this message translates to:
  /// **'Aéroport de départ'**
  String get airportDepartureHint;

  /// No description provided for @airportArrivalHint.
  ///
  /// In fr, this message translates to:
  /// **'Aéroport de destination'**
  String get airportArrivalHint;

  /// No description provided for @passengersAdults.
  ///
  /// In fr, this message translates to:
  /// **'Adultes'**
  String get passengersAdults;

  /// No description provided for @passengersAdultsDesc.
  ///
  /// In fr, this message translates to:
  /// **'12 ans et plus'**
  String get passengersAdultsDesc;

  /// No description provided for @passengersChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get passengersChildren;

  /// No description provided for @passengersChildrenDesc.
  ///
  /// In fr, this message translates to:
  /// **'2-11 ans'**
  String get passengersChildrenDesc;

  /// No description provided for @passengersInfants.
  ///
  /// In fr, this message translates to:
  /// **'Bébés'**
  String get passengersInfants;

  /// No description provided for @passengersInfantsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Moins de 2 ans'**
  String get passengersInfantsDesc;

  /// No description provided for @multiDestFlightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vol {index}'**
  String multiDestFlightTitle(int index);

  /// No description provided for @multiDestDepartureHint.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get multiDestDepartureHint;

  /// No description provided for @multiDestArrivalHint.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get multiDestArrivalHint;

  /// No description provided for @multiDestDateHint.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get multiDestDateHint;

  /// No description provided for @multiDestAddFlightButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un autre vol'**
  String get multiDestAddFlightButton;

  /// No description provided for @maxPriceHint.
  ///
  /// In fr, this message translates to:
  /// **'Prix maximum (€)'**
  String get maxPriceHint;

  /// No description provided for @noFlightsFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vol trouvé'**
  String get noFlightsFoundTitle;

  /// No description provided for @noFlightsFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de modifier vos critères de recherche.'**
  String get noFlightsFoundMessage;

  /// No description provided for @noFlightsFoundPriceFilterMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vol ne correspond à votre budget maximum. Essayez d\'augmenter votre limite de prix ou d\'effacer le filtre.'**
  String get noFlightsFoundPriceFilterMessage;

  /// No description provided for @clearPriceFilterButton.
  ///
  /// In fr, this message translates to:
  /// **'Effacer le filtre de prix'**
  String get clearPriceFilterButton;

  /// No description provided for @selectYourRate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez votre tarif'**
  String get selectYourRate;

  /// No description provided for @outboundFlight.
  ///
  /// In fr, this message translates to:
  /// **'Vol aller'**
  String get outboundFlight;

  /// No description provided for @returnFlight.
  ///
  /// In fr, this message translates to:
  /// **'Vol retour'**
  String get returnFlight;

  /// No description provided for @stopsLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Vol direct} =1{1 escale} other{{count} escales}}'**
  String stopsLabel(int count);

  /// No description provided for @baggageIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Bagages inclus'**
  String get baggageIncluded;

  /// No description provided for @cabinBag.
  ///
  /// In fr, this message translates to:
  /// **'Bagage cabine'**
  String get cabinBag;

  /// No description provided for @checkedBag.
  ///
  /// In fr, this message translates to:
  /// **'Bagage en soute'**
  String get checkedBag;

  /// No description provided for @classAndConditions.
  ///
  /// In fr, this message translates to:
  /// **'Classe et conditions'**
  String get classAndConditions;

  /// No description provided for @bookingClass.
  ///
  /// In fr, this message translates to:
  /// **'Classe de réservation'**
  String get bookingClass;

  /// No description provided for @cabin.
  ///
  /// In fr, this message translates to:
  /// **'Cabine'**
  String get cabin;

  /// No description provided for @fareBasis.
  ///
  /// In fr, this message translates to:
  /// **'Code tarifaire'**
  String get fareBasis;

  /// No description provided for @fareInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations tarifaires'**
  String get fareInformation;

  /// No description provided for @ticketEmissionDeadline.
  ///
  /// In fr, this message translates to:
  /// **'Émission du billet avant le {date}'**
  String ticketEmissionDeadline(String date);

  /// No description provided for @seatsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'{count} siège(s) restant(s) à ce tarif'**
  String seatsRemaining(int count);

  /// No description provided for @baseFare.
  ///
  /// In fr, this message translates to:
  /// **'Tarif de base'**
  String get baseFare;

  /// No description provided for @taxesAndFees.
  ///
  /// In fr, this message translates to:
  /// **'Taxes et frais'**
  String get taxesAndFees;

  /// No description provided for @totalPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix total'**
  String get totalPrice;

  /// No description provided for @bookThisFlight.
  ///
  /// In fr, this message translates to:
  /// **'Réserver ce vol'**
  String get bookThisFlight;

  /// No description provided for @baggageKg.
  ///
  /// In fr, this message translates to:
  /// **'{weight} kg'**
  String baggageKg(int weight);

  /// No description provided for @baggageQuantity.
  ///
  /// In fr, this message translates to:
  /// **'{quantity, plural, =1{1 bagage} other{{quantity} bagages}}'**
  String baggageQuantity(int quantity);

  /// No description provided for @baggageNotIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Non inclus'**
  String get baggageNotIncluded;

  /// No description provided for @handBaggageIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Bagage à main inclus'**
  String get handBaggageIncluded;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @unknownAirline.
  ///
  /// In fr, this message translates to:
  /// **'Compagnie inconnue'**
  String get unknownAirline;

  /// No description provided for @unknownAircraft.
  ///
  /// In fr, this message translates to:
  /// **'Appareil inconnu'**
  String get unknownAircraft;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String error(String message);

  /// No description provided for @searchResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats de recherche'**
  String get searchResults;

  /// No description provided for @departureLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get departureLabel;

  /// No description provided for @destinationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destinationLabel;

  /// No description provided for @travelDatesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Dates de voyage'**
  String get travelDatesLabel;

  /// No description provided for @outboundLabel.
  ///
  /// In fr, this message translates to:
  /// **'Aller'**
  String get outboundLabel;

  /// No description provided for @returnLabel.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get returnLabel;

  /// No description provided for @maxBudgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Budget maximum'**
  String get maxBudgetLabel;

  /// No description provided for @flightCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get flightCardTitle;

  /// No description provided for @hotelCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel'**
  String get hotelCardTitle;

  /// No description provided for @flightAndHotelCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vol + Hôtel'**
  String get flightAndHotelCardTitle;

  /// No description provided for @otherCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get otherCardTitle;

  /// No description provided for @handleBudget.
  ///
  /// In fr, this message translates to:
  /// **'Gérer votre budget'**
  String get handleBudget;

  /// No description provided for @trackExpensesAndPlan.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos dépenses et planifiez votre voyage selon votre budget'**
  String get trackExpensesAndPlan;

  /// No description provided for @addExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get addExpense;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil'**
  String get myProfile;

  /// No description provided for @managePersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos informations personnelles et vos préférences'**
  String get managePersonalInfo;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get disconnect;

  /// No description provided for @viewDestinations.
  ///
  /// In fr, this message translates to:
  /// **'Visualiser les destinations'**
  String get viewDestinations;

  /// No description provided for @exploreDestinations.
  ///
  /// In fr, this message translates to:
  /// **'Explorez les destinations disponibles sur une carte interactive'**
  String get exploreDestinations;

  /// No description provided for @startButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get startButton;

  /// No description provided for @newTrip.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau voyage'**
  String get newTrip;

  /// No description provided for @createYourTrip.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre voyage'**
  String get createYourTrip;

  /// No description provided for @nameTripToStart.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom à votre voyage pour commencer la planification'**
  String get nameTripToStart;

  /// No description provided for @tripNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du voyage'**
  String get tripNameLabel;

  /// No description provided for @tripNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Vacances à Paris'**
  String get tripNameHint;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @aiPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Planification IA'**
  String get aiPlanning;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

  /// No description provided for @searchingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours...'**
  String get searchingInProgress;

  /// No description provided for @typeYourMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tapez votre message...'**
  String get typeYourMessage;

  /// No description provided for @planningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planification {title}'**
  String planningTitle(String title);

  /// No description provided for @personalInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfoTitle;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'EMAIL'**
  String get emailLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'TÉLÉPHONE'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In fr, this message translates to:
  /// **'ADRESSE'**
  String get addressLabel;

  /// No description provided for @modifyButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifyButton;

  /// No description provided for @preferencesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get preferencesTitle;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'LANGUE'**
  String get languageLabel;

  /// No description provided for @themeLabel.
  ///
  /// In fr, this message translates to:
  /// **'THÈME'**
  String get themeLabel;

  /// No description provided for @chooseThemeHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre thème préféré'**
  String get chooseThemeHint;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @profileFooterText.
  ///
  /// In fr, this message translates to:
  /// **'Version {version} · © {year} Vol Airlines'**
  String profileFooterText(String version, int year);

  /// No description provided for @memberSinceText.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis {date}'**
  String memberSinceText(String date);

  /// No description provided for @recentBookingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réservations récentes'**
  String get recentBookingsTitle;

  /// No description provided for @viewAllButton.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAllButton;

  /// No description provided for @noRecentBookings.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réservation récente'**
  String get noRecentBookings;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get bookingStatusConfirmed;

  /// No description provided for @profileLoadFailureMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le profil.'**
  String get profileLoadFailureMessage;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Bag Trip'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous ou créez un compte pour accéder à votre espace'**
  String get loginWelcomeSubtitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get signUp;

  /// No description provided for @loginOrContinueWithEmail.
  ///
  /// In fr, this message translates to:
  /// **'OU CONTINUER AVEC L\'EMAIL'**
  String get loginOrContinueWithEmail;

  /// No description provided for @loginEmailPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get loginEmailPlaceholder;

  /// No description provided for @loginPasswordPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPasswordPlaceholder;

  /// No description provided for @loginForgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get loginForgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginButton;

  /// No description provided for @loginLegalBySigningIn.
  ///
  /// In fr, this message translates to:
  /// **'En vous connectant, vous acceptez les '**
  String get loginLegalBySigningIn;

  /// No description provided for @loginTermsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get loginTermsOfService;

  /// No description provided for @loginPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get loginPrivacyPolicy;

  /// No description provided for @loginLegalAnd.
  ///
  /// In fr, this message translates to:
  /// **' et '**
  String get loginLegalAnd;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginContinueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Apple'**
  String get loginContinueWithApple;

  /// No description provided for @loginFullNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet (optionnel)'**
  String get loginFullNameLabel;

  /// No description provided for @loginFullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Jean Dupont'**
  String get loginFullNameHint;

  /// No description provided for @loginToggleNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas de compte ? S\'inscrire'**
  String get loginToggleNoAccount;

  /// No description provided for @loginToggleHasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ? Se connecter'**
  String get loginToggleHasAccount;

  /// No description provided for @loginErrorEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner votre adresse e-mail'**
  String get loginErrorEmailRequired;

  /// No description provided for @loginErrorEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail incorrecte'**
  String get loginErrorEmailInvalid;

  /// No description provided for @loginErrorPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner votre mot de passe'**
  String get loginErrorPasswordRequired;

  /// No description provided for @loginErrorPasswordMinLength.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get loginErrorPasswordMinLength;

  /// No description provided for @loginRegisterButton.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get loginRegisterButton;

  /// No description provided for @onboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisons votre expérience de voyage en quelques étapes simples.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingFeature1Title.
  ///
  /// In fr, this message translates to:
  /// **'Planification simplifiée'**
  String get onboardingFeature1Title;

  /// No description provided for @onboardingFeature1Desc.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre voyage en quelques étapes. Plus besoin de jongler entre mille onglets.'**
  String get onboardingFeature1Desc;

  /// No description provided for @onboardingFeature2Title.
  ///
  /// In fr, this message translates to:
  /// **'Voyage personnalisé'**
  String get onboardingFeature2Title;

  /// No description provided for @onboardingFeature2Desc.
  ///
  /// In fr, this message translates to:
  /// **'Chaque voyage s\'adapte à vos envies, votre budget et votre rythme.'**
  String get onboardingFeature2Desc;

  /// No description provided for @onboardingFeature3Title.
  ///
  /// In fr, this message translates to:
  /// **'IA à votre service'**
  String get onboardingFeature3Title;

  /// No description provided for @onboardingFeature3Desc.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'idée de destination ? Notre IA vous guide vers le voyage parfait.'**
  String get onboardingFeature3Desc;

  /// No description provided for @onboardingCtaButton.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingCtaButton;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer l\'introduction'**
  String get onboardingSkip;

  /// No description provided for @splashLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get splashLoading;

  /// No description provided for @personalizationPromptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisez votre expérience'**
  String get personalizationPromptTitle;

  /// No description provided for @personalizationPromptSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Quelques questions pour mieux vous connaître et vous proposer des voyages sur mesure.'**
  String get personalizationPromptSubtitle;

  /// No description provided for @personalizationOptionTravelTypes.
  ///
  /// In fr, this message translates to:
  /// **'Vos types de voyage préférés'**
  String get personalizationOptionTravelTypes;

  /// No description provided for @personalizationOptionBudget.
  ///
  /// In fr, this message translates to:
  /// **'Votre budget habituel'**
  String get personalizationOptionBudget;

  /// No description provided for @personalizationOptionCompanions.
  ///
  /// In fr, this message translates to:
  /// **'Avec qui vous voyagez'**
  String get personalizationOptionCompanions;

  /// No description provided for @personalizationCompleteProfile.
  ///
  /// In fr, this message translates to:
  /// **'Compléter mon profil >'**
  String get personalizationCompleteProfile;

  /// No description provided for @personalizationSkipStep.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get personalizationSkipStep;

  /// No description provided for @personalizationProfileSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation de l\'expérience'**
  String get personalizationProfileSectionTitle;

  /// No description provided for @personalizationPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon profil voyage'**
  String get personalizationPageTitle;

  /// No description provided for @personalizationDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get personalizationDone;

  /// No description provided for @personalizationStepTitleTravelTypes.
  ///
  /// In fr, this message translates to:
  /// **'Vos types de voyage préférés'**
  String get personalizationStepTitleTravelTypes;

  /// No description provided for @personalizationStepSubtitleTravelTypes.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un ou plusieurs types'**
  String get personalizationStepSubtitleTravelTypes;

  /// No description provided for @personalizationTravelTypeBeach.
  ///
  /// In fr, this message translates to:
  /// **'Plage & Détente'**
  String get personalizationTravelTypeBeach;

  /// No description provided for @personalizationTravelTypeAdventure.
  ///
  /// In fr, this message translates to:
  /// **'Aventure & Nature'**
  String get personalizationTravelTypeAdventure;

  /// No description provided for @personalizationTravelTypeCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville & Culture'**
  String get personalizationTravelTypeCity;

  /// No description provided for @personalizationTravelTypeGastronomy.
  ///
  /// In fr, this message translates to:
  /// **'Gastronomie'**
  String get personalizationTravelTypeGastronomy;

  /// No description provided for @personalizationTravelTypeWellness.
  ///
  /// In fr, this message translates to:
  /// **'Bien-être & Spa'**
  String get personalizationTravelTypeWellness;

  /// No description provided for @personalizationTravelTypeNightlife.
  ///
  /// In fr, this message translates to:
  /// **'Fête & Vie nocturne'**
  String get personalizationTravelTypeNightlife;

  /// No description provided for @personalizationStepTitleTravelStyle.
  ///
  /// In fr, this message translates to:
  /// **'Votre style de voyage'**
  String get personalizationStepTitleTravelStyle;

  /// No description provided for @personalizationStepSubtitleTravelStyle.
  ///
  /// In fr, this message translates to:
  /// **'Comment aimez-vous organiser vos voyages ?'**
  String get personalizationStepSubtitleTravelStyle;

  /// No description provided for @personalizationTravelStylePlanned.
  ///
  /// In fr, this message translates to:
  /// **'Tout planifié'**
  String get personalizationTravelStylePlanned;

  /// No description provided for @personalizationTravelStyleFlexible.
  ///
  /// In fr, this message translates to:
  /// **'Flexible'**
  String get personalizationTravelStyleFlexible;

  /// No description provided for @personalizationTravelStyleSpontaneous.
  ///
  /// In fr, this message translates to:
  /// **'Spontané'**
  String get personalizationTravelStyleSpontaneous;

  /// No description provided for @personalizationStepTitleBudget.
  ///
  /// In fr, this message translates to:
  /// **'Votre budget habituel'**
  String get personalizationStepTitleBudget;

  /// No description provided for @personalizationStepSubtitleBudget.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre niveau de dépense préféré ?'**
  String get personalizationStepSubtitleBudget;

  /// No description provided for @personalizationBudgetEconomical.
  ///
  /// In fr, this message translates to:
  /// **'Économique'**
  String get personalizationBudgetEconomical;

  /// No description provided for @personalizationBudgetEconomicalDesc.
  ///
  /// In fr, this message translates to:
  /// **'Auberges, transports locaux'**
  String get personalizationBudgetEconomicalDesc;

  /// No description provided for @personalizationBudgetModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get personalizationBudgetModerate;

  /// No description provided for @personalizationBudgetModerateDesc.
  ///
  /// In fr, this message translates to:
  /// **'Hôtels 3★, confort'**
  String get personalizationBudgetModerateDesc;

  /// No description provided for @personalizationBudgetLuxury.
  ///
  /// In fr, this message translates to:
  /// **'Luxe'**
  String get personalizationBudgetLuxury;

  /// No description provided for @personalizationBudgetLuxuryDesc.
  ///
  /// In fr, this message translates to:
  /// **'Hôtels 5★, expériences VIP'**
  String get personalizationBudgetLuxuryDesc;

  /// No description provided for @personalizationStepTitleCompanions.
  ///
  /// In fr, this message translates to:
  /// **'Avec qui voyagez-vous ?'**
  String get personalizationStepTitleCompanions;

  /// No description provided for @personalizationStepSubtitleCompanions.
  ///
  /// In fr, this message translates to:
  /// **'Généralement, vous voyagez...'**
  String get personalizationStepSubtitleCompanions;

  /// No description provided for @personalizationCompanionSolo.
  ///
  /// In fr, this message translates to:
  /// **'Solo'**
  String get personalizationCompanionSolo;

  /// No description provided for @personalizationCompanionCouple.
  ///
  /// In fr, this message translates to:
  /// **'En couple'**
  String get personalizationCompanionCouple;

  /// No description provided for @personalizationCompanionFamily.
  ///
  /// In fr, this message translates to:
  /// **'En famille'**
  String get personalizationCompanionFamily;

  /// No description provided for @personalizationCompanionFriends.
  ///
  /// In fr, this message translates to:
  /// **'Entre amis'**
  String get personalizationCompanionFriends;

  /// No description provided for @personalizationContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get personalizationContinue;

  /// No description provided for @personalizationFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get personalizationFinish;

  /// No description provided for @personalizationSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get personalizationSkip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
