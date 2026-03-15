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

  /// No description provided for @whereNextLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre prochain voyage'**
  String get whereNextLabel;

  /// No description provided for @findYourFlightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez votre vol'**
  String get findYourFlightTitle;

  /// No description provided for @departLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get departLabel;

  /// No description provided for @cabinClassLabel.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get cabinClassLabel;

  /// No description provided for @tripDetailsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détails du voyage'**
  String get tripDetailsLabel;

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

  /// No description provided for @nameLabel.
  ///
  /// In fr, this message translates to:
  /// **'NOM'**
  String get nameLabel;

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

  /// No description provided for @modifyButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifyButton;

  /// No description provided for @editNameTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom'**
  String get editNameTitle;

  /// No description provided for @editPhoneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le téléphone'**
  String get editPhoneTitle;

  /// No description provided for @saveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveButton;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdateSuccess;

  /// No description provided for @profileUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la mise à jour du profil'**
  String get profileUpdateError;

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

  /// No description provided for @personalizationWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get personalizationWelcomeTitle;

  /// No description provided for @personalizationWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisons votre expérience de voyage'**
  String get personalizationWelcomeSubtitle;

  /// No description provided for @personalizationWelcomeCta.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get personalizationWelcomeCta;

  /// No description provided for @personalizationStepTitleHowYouTravel.
  ///
  /// In fr, this message translates to:
  /// **'Comment voyagez-vous ?'**
  String get personalizationStepTitleHowYouTravel;

  /// No description provided for @personalizationStepTitleInterests.
  ///
  /// In fr, this message translates to:
  /// **'Vos centres d\'intérêt'**
  String get personalizationStepTitleInterests;

  /// No description provided for @personalizationStepSubtitleInterests.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un ou plusieurs'**
  String get personalizationStepSubtitleInterests;

  /// No description provided for @personalizationStepTitleBudgetQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Quel est votre budget ?'**
  String get personalizationStepTitleBudgetQuestion;

  /// No description provided for @personalizationStepTitleFrequency.
  ///
  /// In fr, this message translates to:
  /// **'À quelle fréquence voyagez-vous ?'**
  String get personalizationStepTitleFrequency;

  /// No description provided for @personalizationStepSubtitleFrequency.
  ///
  /// In fr, this message translates to:
  /// **'Par an'**
  String get personalizationStepSubtitleFrequency;

  /// No description provided for @personalizationBudgetComfort.
  ///
  /// In fr, this message translates to:
  /// **'Confort'**
  String get personalizationBudgetComfort;

  /// No description provided for @personalizationBudgetComfortDesc.
  ///
  /// In fr, this message translates to:
  /// **'Hôtels 4★, bon équilibre'**
  String get personalizationBudgetComfortDesc;

  /// No description provided for @personalizationFrequency1_2.
  ///
  /// In fr, this message translates to:
  /// **'1–2 fois'**
  String get personalizationFrequency1_2;

  /// No description provided for @personalizationFrequency3_5.
  ///
  /// In fr, this message translates to:
  /// **'3–5 fois'**
  String get personalizationFrequency3_5;

  /// No description provided for @personalizationFrequency6Plus.
  ///
  /// In fr, this message translates to:
  /// **'6+ fois'**
  String get personalizationFrequency6Plus;

  /// No description provided for @personalizationInterestPhotography.
  ///
  /// In fr, this message translates to:
  /// **'Photographie'**
  String get personalizationInterestPhotography;

  /// No description provided for @personalizationInterestShopping.
  ///
  /// In fr, this message translates to:
  /// **'Shopping'**
  String get personalizationInterestShopping;

  /// No description provided for @planifierTab.
  ///
  /// In fr, this message translates to:
  /// **'Planifier'**
  String get planifierTab;

  /// No description provided for @planifierSectionCreateTrip.
  ///
  /// In fr, this message translates to:
  /// **'Créer un voyage'**
  String get planifierSectionCreateTrip;

  /// No description provided for @planifierManualTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifier manuellement'**
  String get planifierManualTitle;

  /// No description provided for @planifierManualDesc.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre voyage étape par étape avec tous les détails'**
  String get planifierManualDesc;

  /// No description provided for @planifierAITitle.
  ///
  /// In fr, this message translates to:
  /// **'Assistant IA'**
  String get planifierAITitle;

  /// No description provided for @planifierAIDesc.
  ///
  /// In fr, this message translates to:
  /// **'Laissez l\'IA vous aider à créer un voyage personnalisé'**
  String get planifierAIDesc;

  /// No description provided for @planifierCompletedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voyages terminés'**
  String get planifierCompletedTitle;

  /// No description provided for @planifierCompletedDesc.
  ///
  /// In fr, this message translates to:
  /// **'Consultez vos voyages passés et budgets'**
  String get planifierCompletedDesc;

  /// No description provided for @planifierGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get planifierGreeting;

  /// No description provided for @planifierMainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez votre\nprochain voyage'**
  String get planifierMainTitle;

  /// No description provided for @planifierSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez et gérez vos voyages'**
  String get planifierSubtitle;

  /// No description provided for @planifierManualDescriptionCard.
  ///
  /// In fr, this message translates to:
  /// **'Construisez votre itinéraire étape par étape.'**
  String get planifierManualDescriptionCard;

  /// No description provided for @planifierAIDescriptionCard.
  ///
  /// In fr, this message translates to:
  /// **'Laissez l\'IA créer un voyage personnalisé pour vous.'**
  String get planifierAIDescriptionCard;

  /// No description provided for @planifierNewBadge.
  ///
  /// In fr, this message translates to:
  /// **'NOUVEAU'**
  String get planifierNewBadge;

  /// No description provided for @planifierSectionExploreDestinations.
  ///
  /// In fr, this message translates to:
  /// **'Explorer les destinations'**
  String get planifierSectionExploreDestinations;

  /// No description provided for @destinationKyoto.
  ///
  /// In fr, this message translates to:
  /// **'Kyoto'**
  String get destinationKyoto;

  /// No description provided for @destinationSantorini.
  ///
  /// In fr, this message translates to:
  /// **'Santorini'**
  String get destinationSantorini;

  /// No description provided for @destinationMarrakech.
  ///
  /// In fr, this message translates to:
  /// **'Marrakech'**
  String get destinationMarrakech;

  /// No description provided for @countryJapan.
  ///
  /// In fr, this message translates to:
  /// **'JAPAN'**
  String get countryJapan;

  /// No description provided for @countryGreece.
  ///
  /// In fr, this message translates to:
  /// **'GREECE'**
  String get countryGreece;

  /// No description provided for @countryMorocco.
  ///
  /// In fr, this message translates to:
  /// **'MOROCCO'**
  String get countryMorocco;

  /// No description provided for @yourDestinationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre destination'**
  String get yourDestinationTitle;

  /// No description provided for @destinationPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Paris, Tokyo, New York...'**
  String get destinationPlaceholder;

  /// No description provided for @numberOfTravelersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de voyageurs'**
  String get numberOfTravelersLabel;

  /// No description provided for @nextButton.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get nextButton;

  /// No description provided for @travelerCount5Plus.
  ///
  /// In fr, this message translates to:
  /// **'5+'**
  String get travelerCount5Plus;

  /// No description provided for @transportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get transportTitle;

  /// No description provided for @transportOptionFlightTitle.
  ///
  /// In fr, this message translates to:
  /// **'Oui, chercher un vol'**
  String get transportOptionFlightTitle;

  /// No description provided for @transportOptionFlightSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche via Amadeus'**
  String get transportOptionFlightSubtitle;

  /// No description provided for @transportOptionOtherTitle.
  ///
  /// In fr, this message translates to:
  /// **'Non, autre transport'**
  String get transportOptionOtherTitle;

  /// No description provided for @transportOptionOtherSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Voiture, train, bus...'**
  String get transportOptionOtherSubtitle;

  /// No description provided for @transportOptionSkipTitle.
  ///
  /// In fr, this message translates to:
  /// **'Non, passer cette étape'**
  String get transportOptionSkipTitle;

  /// No description provided for @transportOptionSkipSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun transport à ajouter'**
  String get transportOptionSkipSubtitle;

  /// No description provided for @otherTransportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Autres transport'**
  String get otherTransportTitle;

  /// No description provided for @transportTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de transport'**
  String get transportTypeLabel;

  /// No description provided for @transportTypeCar.
  ///
  /// In fr, this message translates to:
  /// **'Voiture'**
  String get transportTypeCar;

  /// No description provided for @transportTypeTrain.
  ///
  /// In fr, this message translates to:
  /// **'Train'**
  String get transportTypeTrain;

  /// No description provided for @transportTypeBus.
  ///
  /// In fr, this message translates to:
  /// **'Bus'**
  String get transportTypeBus;

  /// No description provided for @transportTypeFlightBooked.
  ///
  /// In fr, this message translates to:
  /// **'Vol (déjà réservé)'**
  String get transportTypeFlightBooked;

  /// No description provided for @transportDetailsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détails (optionnel)'**
  String get transportDetailsLabel;

  /// No description provided for @transportDetailsPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Location chez Hertz, TGV Paris-Lyon...'**
  String get transportDetailsPlaceholder;

  /// No description provided for @transportBudgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Budget transport (€)'**
  String get transportBudgetLabel;

  /// No description provided for @transportBudgetPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 150'**
  String get transportBudgetPlaceholder;

  /// No description provided for @transportBudgetHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce montant sera ajouté à votre budget voyage'**
  String get transportBudgetHint;

  /// No description provided for @skipThisStepLabel.
  ///
  /// In fr, this message translates to:
  /// **'Passer cette étape'**
  String get skipThisStepLabel;

  /// No description provided for @recapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get recapTitle;

  /// No description provided for @recapFinalStepLabel.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPE FINALE'**
  String get recapFinalStepLabel;

  /// No description provided for @recapDateChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get recapDateChoose;

  /// No description provided for @recapDateSelectHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get recapDateSelectHint;

  /// No description provided for @recapTravelTypesLabel.
  ///
  /// In fr, this message translates to:
  /// **'TYPES DE VOYAGE'**
  String get recapTravelTypesLabel;

  /// No description provided for @recapStyleLabel.
  ///
  /// In fr, this message translates to:
  /// **'STYLE'**
  String get recapStyleLabel;

  /// No description provided for @recapBudgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'BUDGET'**
  String get recapBudgetLabel;

  /// No description provided for @recapCompanionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'COMPAGNONS'**
  String get recapCompanionsLabel;

  /// No description provided for @recapLaunchSearchButton.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la recherche IA'**
  String get recapLaunchSearchButton;

  /// No description provided for @summaryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre voyage personnalisé'**
  String get summaryTitle;

  /// No description provided for @summarySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'+ Généré par l\'IA'**
  String get summarySubtitle;

  /// No description provided for @summaryUpcomingJourney.
  ///
  /// In fr, this message translates to:
  /// **'◆ PROCHAIN VOYAGE'**
  String get summaryUpcomingJourney;

  /// No description provided for @summaryDays.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get summaryDays;

  /// No description provided for @summaryBudget.
  ///
  /// In fr, this message translates to:
  /// **'budget'**
  String get summaryBudget;

  /// No description provided for @summarySolo.
  ///
  /// In fr, this message translates to:
  /// **'Solo'**
  String get summarySolo;

  /// No description provided for @summarySectionCurated.
  ///
  /// In fr, this message translates to:
  /// **'POUR VOUS'**
  String get summarySectionCurated;

  /// No description provided for @summaryTripHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Points forts du voyage'**
  String get summaryTripHighlights;

  /// No description provided for @summarySectionWhereStay.
  ///
  /// In fr, this message translates to:
  /// **'OÙ LOGER'**
  String get summarySectionWhereStay;

  /// No description provided for @summaryAccommodation.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement'**
  String get summaryAccommodation;

  /// No description provided for @summarySectionFlight.
  ///
  /// In fr, this message translates to:
  /// **'VOL'**
  String get summarySectionFlight;

  /// No description provided for @summaryFlight.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get summaryFlight;

  /// No description provided for @summaryFlightRouteMock.
  ///
  /// In fr, this message translates to:
  /// **'Paris CDG → Paris Orly'**
  String get summaryFlightRouteMock;

  /// No description provided for @summaryFlightDetailsMock.
  ///
  /// In fr, this message translates to:
  /// **'Aller-retour · Économique'**
  String get summaryFlightDetailsMock;

  /// No description provided for @summarySectionYourJourney.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE VOYAGE'**
  String get summarySectionYourJourney;

  /// No description provided for @summaryDayByDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour par jour'**
  String get summaryDayByDay;

  /// No description provided for @summarySectionEssentials.
  ///
  /// In fr, this message translates to:
  /// **'ESSENTIELS'**
  String get summarySectionEssentials;

  /// No description provided for @summaryWhatToBring.
  ///
  /// In fr, this message translates to:
  /// **'À emporter'**
  String get summaryWhatToBring;

  /// No description provided for @summaryBestPick.
  ///
  /// In fr, this message translates to:
  /// **'Best pick'**
  String get summaryBestPick;

  /// No description provided for @summaryDayPrefix.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get summaryDayPrefix;

  /// No description provided for @summaryDay1Date.
  ///
  /// In fr, this message translates to:
  /// **'LUNDI · 9 JUIN'**
  String get summaryDay1Date;

  /// No description provided for @summaryDay2Date.
  ///
  /// In fr, this message translates to:
  /// **'MARDI · 10 JUIN'**
  String get summaryDay2Date;

  /// No description provided for @summaryDay3Date.
  ///
  /// In fr, this message translates to:
  /// **'MERCREDI · 11 JUIN'**
  String get summaryDay3Date;

  /// No description provided for @summaryDay4Date.
  ///
  /// In fr, this message translates to:
  /// **'JEUDI · 12 JUIN'**
  String get summaryDay4Date;

  /// No description provided for @summaryDay5Date.
  ///
  /// In fr, this message translates to:
  /// **'VENDREDI · 13 JUIN'**
  String get summaryDay5Date;

  /// No description provided for @summaryDay1Description.
  ///
  /// In fr, this message translates to:
  /// **'Installation au Marais, balade dans les rues historiques, apéritif en soirée place des Vosges.'**
  String get summaryDay1Description;

  /// No description provided for @summaryDay2Description.
  ///
  /// In fr, this message translates to:
  /// **'Louvre le matin, quartier Notre-Dame, berges de la Seine l\'après-midi.'**
  String get summaryDay2Description;

  /// No description provided for @summaryDay3Description.
  ///
  /// In fr, this message translates to:
  /// **'Atelier cuisine, marché, dîner dans un bistro typique.'**
  String get summaryDay3Description;

  /// No description provided for @summaryDay4Description.
  ///
  /// In fr, this message translates to:
  /// **'Château de Versailles, la Galerie des Glaces et les jardins en fleurs.'**
  String get summaryDay4Description;

  /// No description provided for @summaryDay5Description.
  ///
  /// In fr, this message translates to:
  /// **'Matin à Sacré-Cœur, dernier café crème, vol retour l\'après-midi.'**
  String get summaryDay5Description;

  /// No description provided for @summaryCategoryTravelDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour de voyage'**
  String get summaryCategoryTravelDay;

  /// No description provided for @summaryCategoryCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get summaryCategoryCulture;

  /// No description provided for @summaryCategoryCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get summaryCategoryCuisine;

  /// No description provided for @summaryCategoryDayTrip.
  ///
  /// In fr, this message translates to:
  /// **'Excursion'**
  String get summaryCategoryDayTrip;

  /// No description provided for @summaryCategoryDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get summaryCategoryDeparture;

  /// No description provided for @summarySaveTrip.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder ce voyage'**
  String get summarySaveTrip;

  /// No description provided for @summaryRegenerate.
  ///
  /// In fr, this message translates to:
  /// **'Régénérer'**
  String get summaryRegenerate;

  /// No description provided for @summaryTripSaved.
  ///
  /// In fr, this message translates to:
  /// **'Voyage sauvegardé'**
  String get summaryTripSaved;

  /// No description provided for @summaryDaysCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String summaryDaysCount(int count);

  /// No description provided for @summaryBudgetAmount.
  ///
  /// In fr, this message translates to:
  /// **'{amount} budget'**
  String summaryBudgetAmount(String amount);

  /// No description provided for @activities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get activities;

  /// No description provided for @addActivity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une activité'**
  String get addActivity;

  /// No description provided for @editActivity.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’activité'**
  String get editActivity;

  /// No description provided for @noActivities.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get noActivities;

  /// No description provided for @activityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get activityTitle;

  /// No description provided for @activityDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get activityDate;

  /// No description provided for @activityDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get activityDescription;

  /// No description provided for @activityStartTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de début'**
  String get activityStartTime;

  /// No description provided for @activityEndTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de fin'**
  String get activityEndTime;

  /// No description provided for @activityLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get activityLocation;

  /// No description provided for @activityCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get activityCategory;

  /// No description provided for @activityEstimatedCost.
  ///
  /// In fr, this message translates to:
  /// **'Coût estimé'**
  String get activityEstimatedCost;

  /// No description provided for @activityBooked.
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get activityBooked;

  /// No description provided for @categoryVisit.
  ///
  /// In fr, this message translates to:
  /// **'Visite'**
  String get categoryVisit;

  /// No description provided for @categoryRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get categoryRestaurant;

  /// No description provided for @categoryTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryLeisure.
  ///
  /// In fr, this message translates to:
  /// **'Loisir'**
  String get categoryLeisure;

  /// No description provided for @categoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get categoryOther;

  /// No description provided for @budgetItems.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get budgetItems;

  /// No description provided for @editExpense.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get editExpense;

  /// No description provided for @noExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense'**
  String get noExpenses;

  /// No description provided for @expenseLabel.
  ///
  /// In fr, this message translates to:
  /// **'Libellé'**
  String get expenseLabel;

  /// No description provided for @expenseAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get expenseAmount;

  /// No description provided for @expenseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get expenseCategory;

  /// No description provided for @expenseDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @expensePlanned.
  ///
  /// In fr, this message translates to:
  /// **'Planifié'**
  String get expensePlanned;

  /// No description provided for @expenseReal.
  ///
  /// In fr, this message translates to:
  /// **'Réel'**
  String get expenseReal;

  /// No description provided for @budgetTotal.
  ///
  /// In fr, this message translates to:
  /// **'Budget total'**
  String get budgetTotal;

  /// No description provided for @budgetSpent.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get budgetSpent;

  /// No description provided for @budgetRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Restant'**
  String get budgetRemaining;

  /// No description provided for @categoryFlight.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get categoryFlight;

  /// No description provided for @categoryAccommodation.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement'**
  String get categoryAccommodation;

  /// No description provided for @categoryFood.
  ///
  /// In fr, this message translates to:
  /// **'Nourriture'**
  String get categoryFood;

  /// No description provided for @categoryActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get categoryActivity;

  /// No description provided for @budgetExceeded.
  ///
  /// In fr, this message translates to:
  /// **'Budget dépassé de {amount} €'**
  String budgetExceeded(String amount);

  /// No description provided for @budgetWarning.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez utilisé {percent}% de votre budget'**
  String budgetWarning(String percent);

  /// No description provided for @tripCompletedReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Ce voyage est terminé. Les données sont en lecture seule.'**
  String get tripCompletedReadOnly;

  /// No description provided for @markAsReady.
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme prêt'**
  String get markAsReady;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// No description provided for @addButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addButton;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @errorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get errorTitle;

  /// No description provided for @backButton.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get backButton;

  /// No description provided for @tabHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// No description provided for @tabActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get tabActivity;

  /// No description provided for @tabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer lu'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get notificationsEmpty;

  /// No description provided for @notificationsToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get notificationsToday;

  /// No description provided for @notificationsYesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationsYesterday;

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} jours'**
  String notificationsDaysAgo(int count);

  /// No description provided for @baggageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bagages'**
  String get baggageTitle;

  /// No description provided for @baggageSuggestionsTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get baggageSuggestionsTooltip;

  /// No description provided for @baggageCategoryDocuments.
  ///
  /// In fr, this message translates to:
  /// **'Documents'**
  String get baggageCategoryDocuments;

  /// No description provided for @baggageCategoryClothing.
  ///
  /// In fr, this message translates to:
  /// **'Vêtements'**
  String get baggageCategoryClothing;

  /// No description provided for @baggageCategoryElectronics.
  ///
  /// In fr, this message translates to:
  /// **'Électronique'**
  String get baggageCategoryElectronics;

  /// No description provided for @baggageCategoryHygiene.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène'**
  String get baggageCategoryHygiene;

  /// No description provided for @baggageCategoryMedication.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get baggageCategoryMedication;

  /// No description provided for @baggageCategoryAccessories.
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get baggageCategoryAccessories;

  /// No description provided for @baggageCategoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get baggageCategoryOther;

  /// No description provided for @baggageDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'élément'**
  String get baggageDeleteTitle;

  /// No description provided for @baggageDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet élément ?'**
  String get baggageDeleteConfirm;

  /// No description provided for @baggageItemAdded.
  ///
  /// In fr, this message translates to:
  /// **'Élément ajouté'**
  String get baggageItemAdded;

  /// No description provided for @baggageItemDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Élément supprimé'**
  String get baggageItemDeleted;

  /// No description provided for @baggageItemAddedFromSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Élément ajouté depuis suggestion'**
  String get baggageItemAddedFromSuggestion;

  /// No description provided for @baggageQuantityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get baggageQuantityLabel;

  /// No description provided for @baggageCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie (optionnel)'**
  String get baggageCategoryLabel;

  /// No description provided for @baggageEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément'**
  String get baggageEmptyTitle;

  /// No description provided for @baggageEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des éléments à votre liste de bagages'**
  String get baggageEmptySubtitle;

  /// No description provided for @baggageAddItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get baggageAddItemTitle;

  /// No description provided for @accommodationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hébergements'**
  String get accommodationsTitle;

  /// No description provided for @accommodationCheckInHelp.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'arrivée'**
  String get accommodationCheckInHelp;

  /// No description provided for @accommodationCheckOutHelp.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get accommodationCheckOutHelp;

  /// No description provided for @accommodationAdded.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement ajouté avec succès'**
  String get accommodationAdded;

  /// No description provided for @accommodationDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'hébergement'**
  String get accommodationDeleteTitle;

  /// No description provided for @accommodationDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet hébergement ?'**
  String get accommodationDeleteConfirm;

  /// No description provided for @accommodationDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement supprimé'**
  String get accommodationDeleted;

  /// No description provided for @accommodationCheckInLabel.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get accommodationCheckInLabel;

  /// No description provided for @accommodationCheckOutLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get accommodationCheckOutLabel;

  /// No description provided for @accommodationEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun hébergement'**
  String get accommodationEmptyTitle;

  /// No description provided for @accommodationEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos hôtels et logements'**
  String get accommodationEmptySubtitle;

  /// No description provided for @accommodationAddTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un hébergement'**
  String get accommodationAddTitle;

  /// No description provided for @tripTravelers.
  ///
  /// In fr, this message translates to:
  /// **'Voyageurs'**
  String get tripTravelers;

  /// No description provided for @tripDaysRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Jours restants'**
  String get tripDaysRemaining;

  /// No description provided for @tripTravelDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours de voyage'**
  String get tripTravelDays;

  /// No description provided for @tripComplete.
  ///
  /// In fr, this message translates to:
  /// **'Terminer le voyage'**
  String get tripComplete;

  /// No description provided for @tripDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le voyage'**
  String get tripDeleteTitle;

  /// No description provided for @tripDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ce voyage ? Cette action est irréversible.'**
  String get tripDeleteConfirm;

  /// No description provided for @tripGiveReview.
  ///
  /// In fr, this message translates to:
  /// **'Donner un avis'**
  String get tripGiveReview;

  /// No description provided for @tripsMyTrips.
  ///
  /// In fr, this message translates to:
  /// **'Mes voyages'**
  String get tripsMyTrips;

  /// No description provided for @tripsNewTrip.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau voyage'**
  String get tripsNewTrip;

  /// No description provided for @tripStatusOngoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get tripStatusOngoing;

  /// No description provided for @tripStatusPlanned.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get tripStatusPlanned;

  /// No description provided for @tripStatusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get tripStatusCompleted;

  /// No description provided for @tripsEmptyOngoing.
  ///
  /// In fr, this message translates to:
  /// **'Aucun voyage en cours'**
  String get tripsEmptyOngoing;

  /// No description provided for @tripsEmptyPlanned.
  ///
  /// In fr, this message translates to:
  /// **'Aucun voyage planifié'**
  String get tripsEmptyPlanned;

  /// No description provided for @tripsEmptyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Aucun voyage terminé'**
  String get tripsEmptyCompleted;

  /// No description provided for @sharesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partages'**
  String get sharesTitle;

  /// No description provided for @sharesInviteButton.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get sharesInviteButton;

  /// No description provided for @sharesRevokeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer l\'accès'**
  String get sharesRevokeTitle;

  /// No description provided for @sharesRevokeConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir révoquer l\'accès de cet utilisateur ?'**
  String get sharesRevokeConfirm;

  /// No description provided for @sharesRevokeButton.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get sharesRevokeButton;

  /// No description provided for @sharesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partage'**
  String get sharesEmpty;

  /// No description provided for @sharesEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez des personnes à consulter votre voyage'**
  String get sharesEmptySubtitle;

  /// No description provided for @tripCreated.
  ///
  /// In fr, this message translates to:
  /// **'Voyage créé !'**
  String get tripCreated;

  /// No description provided for @aiResultsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Résultats IA'**
  String get aiResultsTitle;

  /// No description provided for @feedbackTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get feedbackTitle;

  /// No description provided for @feedbackGiveReview.
  ///
  /// In fr, this message translates to:
  /// **'Donner un avis'**
  String get feedbackGiveReview;

  /// No description provided for @feedbackAllReviews.
  ///
  /// In fr, this message translates to:
  /// **'Tous les avis'**
  String get feedbackAllReviews;

  /// No description provided for @feedbackGiveYourReview.
  ///
  /// In fr, this message translates to:
  /// **'Donner votre avis'**
  String get feedbackGiveYourReview;

  /// No description provided for @feedbackOverallRating.
  ///
  /// In fr, this message translates to:
  /// **'Note globale'**
  String get feedbackOverallRating;

  /// No description provided for @feedbackHighlights.
  ///
  /// In fr, this message translates to:
  /// **'Points forts'**
  String get feedbackHighlights;

  /// No description provided for @feedbackHighlightsHint.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'avez-vous aimé ?'**
  String get feedbackHighlightsHint;

  /// No description provided for @feedbackLowlights.
  ///
  /// In fr, this message translates to:
  /// **'Points faibles'**
  String get feedbackLowlights;

  /// No description provided for @feedbackLowlightsHint.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui pourrait être amélioré ?'**
  String get feedbackLowlightsHint;

  /// No description provided for @feedbackWouldRecommend.
  ///
  /// In fr, this message translates to:
  /// **'Recommanderiez-vous ce voyage ?'**
  String get feedbackWouldRecommend;

  /// No description provided for @feedbackThanks.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre avis !'**
  String get feedbackThanks;

  /// No description provided for @feedbackSubmitButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer mon avis'**
  String get feedbackSubmitButton;

  /// No description provided for @feedbackSent.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis a été envoyé'**
  String get feedbackSent;

  /// No description provided for @feedbackRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Recommandé : '**
  String get feedbackRecommended;

  /// No description provided for @feedbackDiscoverNextTrip.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir mon prochain voyage'**
  String get feedbackDiscoverNextTrip;

  /// No description provided for @feedbackDiscoverText.
  ///
  /// In fr, this message translates to:
  /// **'Découvrez votre prochain voyage idéal basé sur vos expériences.'**
  String get feedbackDiscoverText;

  /// No description provided for @postTripSuggestionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prochain voyage suggéré'**
  String get postTripSuggestionTitle;

  /// No description provided for @postTripNextTrip.
  ///
  /// In fr, this message translates to:
  /// **'Votre prochain voyage'**
  String get postTripNextTrip;

  /// No description provided for @postTripBasedOnPreferences.
  ///
  /// In fr, this message translates to:
  /// **'Basé sur vos préférences'**
  String get postTripBasedOnPreferences;

  /// No description provided for @postTripProposedActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités proposées'**
  String get postTripProposedActivities;

  /// No description provided for @postTripCreateTrip.
  ///
  /// In fr, this message translates to:
  /// **'Créer ce voyage'**
  String get postTripCreateTrip;

  /// No description provided for @filterCabinBagIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Bagage cabine inclus'**
  String get filterCabinBagIncluded;

  /// No description provided for @filterCheckedBagIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Bagage soute inclus'**
  String get filterCheckedBagIncluded;

  /// No description provided for @filterReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get filterReset;

  /// No description provided for @premiumFeatureAiUnlimited.
  ///
  /// In fr, this message translates to:
  /// **'Générations IA illimitées'**
  String get premiumFeatureAiUnlimited;

  /// No description provided for @premiumFeatureViewers.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'à 10 viewers par trip'**
  String get premiumFeatureViewers;

  /// No description provided for @premiumFeatureOfflineNotifs.
  ///
  /// In fr, this message translates to:
  /// **'Notifications hors-ligne'**
  String get premiumFeatureOfflineNotifs;

  /// No description provided for @premiumFeaturePostTrip.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions post-voyage IA'**
  String get premiumFeaturePostTrip;

  /// No description provided for @premiumCtaButton.
  ///
  /// In fr, this message translates to:
  /// **'Passer à Premium - 9,99€/mois'**
  String get premiumCtaButton;

  /// No description provided for @profileConfigurePreferences.
  ///
  /// In fr, this message translates to:
  /// **'Configurez vos préférences'**
  String get profileConfigurePreferences;

  /// No description provided for @profileStyleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Style : {style}'**
  String profileStyleLabel(String style);

  /// No description provided for @profileBudgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'Budget : {budget}'**
  String profileBudgetLabel(String budget);

  /// No description provided for @profileCompanionsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compagnons : {companions}'**
  String profileCompanionsLabel(String companions);

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Vérifiez votre connexion internet.'**
  String get errorNetwork;

  /// No description provided for @errorAuth.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects ou session expirée.'**
  String get errorAuth;

  /// No description provided for @errorForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ressource non trouvée.'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In fr, this message translates to:
  /// **'Requête invalide.'**
  String get errorValidation;

  /// No description provided for @errorQuota.
  ///
  /// In fr, this message translates to:
  /// **'Limite atteinte. Passez à Premium pour continuer.'**
  String get errorQuota;

  /// No description provided for @errorStaleContext.
  ///
  /// In fr, this message translates to:
  /// **'Le contexte a été mis à jour. Veuillez rafraîchir.'**
  String get errorStaleContext;

  /// No description provided for @errorServer.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur. Veuillez réessayer plus tard.'**
  String get errorServer;

  /// No description provided for @errorRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de requêtes. Veuillez patienter.'**
  String get errorRateLimit;

  /// No description provided for @errorCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Opération annulée.'**
  String get errorCancelled;

  /// No description provided for @errorUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get errorUnknown;

  /// No description provided for @errorSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée'**
  String get errorSessionExpired;

  /// No description provided for @bookingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get bookingLabel;

  /// No description provided for @activitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get activitiesTitle;

  /// No description provided for @activitiesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get activitiesEmpty;

  /// No description provided for @activitiesEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des activités pour planifier votre voyage'**
  String get activitiesEmptySubtitle;

  /// No description provided for @activitiesSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get activitiesSuggestionsTitle;

  /// No description provided for @activityFormNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle activité'**
  String get activityFormNew;

  /// No description provided for @activityFormEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'activité'**
  String get activityFormEdit;

  /// No description provided for @activityTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le titre est requis'**
  String get activityTitleRequired;

  /// No description provided for @activityFormCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get activityFormCreate;

  /// No description provided for @activityFormUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get activityFormUpdate;

  /// No description provided for @activityFormBooked.
  ///
  /// In fr, this message translates to:
  /// **'Réservé'**
  String get activityFormBooked;

  /// No description provided for @feedbackYesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get feedbackYesLabel;

  /// No description provided for @feedbackNoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get feedbackNoLabel;

  /// No description provided for @offlineMode.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors ligne. Données en cache affichées.'**
  String get offlineMode;

  /// No description provided for @offlineWriteError.
  ///
  /// In fr, this message translates to:
  /// **'Cette action nécessite une connexion internet.'**
  String get offlineWriteError;

  /// No description provided for @loadingMore.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loadingMore;

  /// No description provided for @noMoreItems.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'éléments'**
  String get noMoreItems;

  /// No description provided for @subscriptionVerifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de votre abonnement...'**
  String get subscriptionVerifying;

  /// No description provided for @subscriptionWelcomePremium.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue en Premium !'**
  String get subscriptionWelcomePremium;

  /// No description provided for @subscriptionPending.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement en attente'**
  String get subscriptionPending;

  /// No description provided for @subscriptionSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez désormais accès à toutes les fonctionnalités premium. Profitez des générations IA illimitées et plus encore !'**
  String get subscriptionSuccessMessage;

  /// No description provided for @subscriptionPendingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement est en cours de traitement. L\'activation peut prendre un instant.'**
  String get subscriptionPendingMessage;

  /// No description provided for @subscriptionCancelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement non complété'**
  String get subscriptionCancelTitle;

  /// No description provided for @subscriptionCancelMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement d\'abonnement n\'a pas été finalisé. Vous pouvez réessayer ou retourner à votre profil.'**
  String get subscriptionCancelMessage;

  /// No description provided for @subscriptionBackToProfile.
  ///
  /// In fr, this message translates to:
  /// **'Retour au profil'**
  String get subscriptionBackToProfile;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement confirmé !'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre réservation de vol a été confirmée. Vous pouvez la consulter dans vos voyages.'**
  String get paymentSuccessMessage;

  /// No description provided for @paymentBackToTrips.
  ///
  /// In fr, this message translates to:
  /// **'Retour à mes voyages'**
  String get paymentBackToTrips;

  /// No description provided for @paymentCancelledTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement annulé'**
  String get paymentCancelledTitle;

  /// No description provided for @paymentCancelledMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement a été annulé. Aucun montant n\'a été débité.'**
  String get paymentCancelledMessage;

  /// No description provided for @payment3dsReturnTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours'**
  String get payment3dsReturnTitle;

  /// No description provided for @payment3dsReturnMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement est en cours de traitement. Vous recevrez une confirmation sous peu.'**
  String get payment3dsReturnMessage;

  /// No description provided for @nextTripSection.
  ///
  /// In fr, this message translates to:
  /// **'Prochain voyage'**
  String get nextTripSection;

  /// No description provided for @nextTripCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days} jours'**
  String nextTripCountdown(int days);

  /// No description provided for @nextTripNoUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'Aucun voyage prévu'**
  String get nextTripNoUpcoming;

  /// No description provided for @nextTripReady.
  ///
  /// In fr, this message translates to:
  /// **'{percent}% prêt'**
  String nextTripReady(int percent);

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settingsTitle;

  /// No description provided for @personalInfoPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfoPageTitle;

  /// No description provided for @travelPreferencesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préférences de voyage'**
  String get travelPreferencesTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bon voyage, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à voyager ?'**
  String get homeWelcomeTitle;

  /// No description provided for @homeWelcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier voyage en quelques étapes. Manuel ou assisté par l\'IA — à vous de choisir.'**
  String get homeWelcomeSubtitle;

  /// No description provided for @homeCreateFirstTrip.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon premier voyage'**
  String get homeCreateFirstTrip;

  /// No description provided for @planTripCta.
  ///
  /// In fr, this message translates to:
  /// **'Planifier un voyage'**
  String get planTripCta;

  /// No description provided for @planTripCtaSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Manuel ou assisté par l\'IA'**
  String get planTripCtaSubtitle;

  /// No description provided for @inspireMe.
  ///
  /// In fr, this message translates to:
  /// **'Inspire-moi'**
  String get inspireMe;

  /// No description provided for @datesLabel.
  ///
  /// In fr, this message translates to:
  /// **'DATES'**
  String get datesLabel;

  /// No description provided for @suggestedDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée suggérée'**
  String get suggestedDuration;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get days;

  /// No description provided for @reviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get reviewTitle;

  /// No description provided for @aiSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'SUGGESTIONS IA'**
  String get aiSuggestionsTitle;

  /// No description provided for @createTripButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer le voyage'**
  String get createTripButton;

  /// No description provided for @tripCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Voyage créé avec succès !'**
  String get tripCreatedSuccess;

  /// No description provided for @stepDestination.
  ///
  /// In fr, this message translates to:
  /// **'Où ?'**
  String get stepDestination;

  /// No description provided for @stepDates.
  ///
  /// In fr, this message translates to:
  /// **'Quand ?'**
  String get stepDates;

  /// No description provided for @stepTravelers.
  ///
  /// In fr, this message translates to:
  /// **'Qui ?'**
  String get stepTravelers;

  /// No description provided for @stepReview.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get stepReview;

  /// No description provided for @toValidateBadge.
  ///
  /// In fr, this message translates to:
  /// **'A valider'**
  String get toValidateBadge;

  /// No description provided for @addFirstAccommodation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un hébergement'**
  String get addFirstAccommodation;

  /// No description provided for @addFirstActivity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une activité'**
  String get addFirstActivity;

  /// No description provided for @addFirstBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Préparer vos bagages'**
  String get addFirstBaggage;

  /// No description provided for @addFirstBudget.
  ///
  /// In fr, this message translates to:
  /// **'Suivre vos dépenses'**
  String get addFirstBudget;

  /// No description provided for @budgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @transportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transports'**
  String get transportsTitle;

  /// No description provided for @addFirstTransport.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre vol'**
  String get addFirstTransport;

  /// No description provided for @addFlight.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un vol'**
  String get addFlight;

  /// No description provided for @addFlightSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre numéro de vol pour obtenir les infos en direct'**
  String get addFlightSubtitle;

  /// No description provided for @searchFlightOption.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un vol'**
  String get searchFlightOption;

  /// No description provided for @searchFlightOptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez et comparez des vols'**
  String get searchFlightOptionSubtitle;

  /// No description provided for @addManuallyOption.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter manuellement'**
  String get addManuallyOption;

  /// No description provided for @addManuallyOptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez les détails du vol'**
  String get addManuallyOptionSubtitle;

  /// No description provided for @mainFlightsSection.
  ///
  /// In fr, this message translates to:
  /// **'Vols principaux'**
  String get mainFlightsSection;

  /// No description provided for @internalFlightsSection.
  ///
  /// In fr, this message translates to:
  /// **'Vols internes'**
  String get internalFlightsSection;

  /// No description provided for @flightNumberLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de vol'**
  String get flightNumberLabel;

  /// No description provided for @flightNumberRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de vol est requis'**
  String get flightNumberRequired;

  /// No description provided for @airlineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Compagnie aérienne'**
  String get airlineLabel;

  /// No description provided for @departureAirportLabel.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get departureAirportLabel;

  /// No description provided for @arrivalAirportLabel.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get arrivalAirportLabel;

  /// No description provided for @departureDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date de départ'**
  String get departureDateLabel;

  /// No description provided for @arrivalDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'arrivée'**
  String get arrivalDateLabel;

  /// No description provided for @priceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get priceLabel;

  /// No description provided for @notesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @mainFlightType.
  ///
  /// In fr, this message translates to:
  /// **'Principal'**
  String get mainFlightType;

  /// No description provided for @internalFlightType.
  ///
  /// In fr, this message translates to:
  /// **'Interne'**
  String get internalFlightType;

  /// No description provided for @flightStatusOnTime.
  ///
  /// In fr, this message translates to:
  /// **'À l\'heure'**
  String get flightStatusOnTime;

  /// No description provided for @flightStatusDelayed.
  ///
  /// In fr, this message translates to:
  /// **'Retardé'**
  String get flightStatusDelayed;

  /// No description provided for @flightStatusCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get flightStatusCancelled;

  /// No description provided for @flightStatusLanded.
  ///
  /// In fr, this message translates to:
  /// **'Atterri'**
  String get flightStatusLanded;

  /// No description provided for @flightStatusScheduled.
  ///
  /// In fr, this message translates to:
  /// **'Programmé'**
  String get flightStatusScheduled;
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
