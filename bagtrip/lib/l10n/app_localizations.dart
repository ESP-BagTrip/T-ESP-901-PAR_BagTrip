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

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get disconnect;

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @retryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retryButton;

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

  /// No description provided for @personalizationProfileSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalisation de l\'expérience'**
  String get personalizationProfileSectionTitle;

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

  /// No description provided for @planifierGreeting.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get planifierGreeting;

  /// No description provided for @destinationPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Paris, Tokyo, New York...'**
  String get destinationPlaceholder;

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

  /// No description provided for @summarySectionWhereStay.
  ///
  /// In fr, this message translates to:
  /// **'OÙ LOGER'**
  String get summarySectionWhereStay;

  /// No description provided for @summarySectionFlight.
  ///
  /// In fr, this message translates to:
  /// **'VOL'**
  String get summarySectionFlight;

  /// No description provided for @summarySectionYourJourney.
  ///
  /// In fr, this message translates to:
  /// **'VOTRE VOYAGE'**
  String get summarySectionYourJourney;

  /// No description provided for @summarySectionEssentials.
  ///
  /// In fr, this message translates to:
  /// **'ESSENTIELS'**
  String get summarySectionEssentials;

  /// No description provided for @summaryDayPrefix.
  ///
  /// In fr, this message translates to:
  /// **'J'**
  String get summaryDayPrefix;

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

  /// No description provided for @activityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get activityTitle;

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

  /// No description provided for @activityDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'activité'**
  String get activityDeleteTitle;

  /// No description provided for @activityDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette activité ?'**
  String get activityDeleteConfirm;

  /// No description provided for @activityEndTimeBeforeStartTime.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de fin doit être après l\'heure de début'**
  String get activityEndTimeBeforeStartTime;

  /// No description provided for @categoryTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

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

  /// No description provided for @addExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get editExpense;

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

  /// No description provided for @expenseLabelRequired.
  ///
  /// In fr, this message translates to:
  /// **'Libellé requis'**
  String get expenseLabelRequired;

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

  /// No description provided for @notificationsJustNow.
  ///
  /// In fr, this message translates to:
  /// **'À l\'instant'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} min'**
  String notificationsMinutesAgo(int count);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count}h'**
  String notificationsHoursAgo(int count);

  /// No description provided for @notificationsShortDaysAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count}j'**
  String notificationsShortDaysAgo(int count);

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

  /// No description provided for @baggageAddItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get baggageAddItemTitle;

  /// No description provided for @baggagePackedCount.
  ///
  /// In fr, this message translates to:
  /// **'{packed} sur {total} emballés'**
  String baggagePackedCount(int packed, int total);

  /// No description provided for @baggageSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions pour vous'**
  String get baggageSuggestionsTitle;

  /// No description provided for @baggageToPack.
  ///
  /// In fr, this message translates to:
  /// **'À emballer'**
  String get baggageToPack;

  /// No description provided for @baggagePacked.
  ///
  /// In fr, this message translates to:
  /// **'Emballés'**
  String get baggagePacked;

  /// No description provided for @baggageSwipeToPack.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour emballer'**
  String get baggageSwipeToPack;

  /// No description provided for @baggageUnpack.
  ///
  /// In fr, this message translates to:
  /// **'Déballer'**
  String get baggageUnpack;

  /// No description provided for @baggageEditItemTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'élément'**
  String get baggageEditItemTitle;

  /// No description provided for @baggageItemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'élément'**
  String get baggageItemName;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get fieldRequired;

  /// No description provided for @accommodationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hébergements'**
  String get accommodationsTitle;

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

  /// No description provided for @postTripSuggestionDuration.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours'**
  String postTripSuggestionDuration(int days);

  /// No description provided for @postTripSuggestionBudget.
  ///
  /// In fr, this message translates to:
  /// **'{amount}€'**
  String postTripSuggestionBudget(String amount);

  /// No description provided for @feedbackNoReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis'**
  String get feedbackNoReviews;

  /// No description provided for @feedbackHighlightsPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Points forts : {highlights}'**
  String feedbackHighlightsPrefix(String highlights);

  /// No description provided for @feedbackLowlightsPrefix.
  ///
  /// In fr, this message translates to:
  /// **'À améliorer : {lowlights}'**
  String feedbackLowlightsPrefix(String lowlights);

  /// No description provided for @feedbackRecommends.
  ///
  /// In fr, this message translates to:
  /// **'Recommande'**
  String get feedbackRecommends;

  /// No description provided for @feedbackNotRecommends.
  ///
  /// In fr, this message translates to:
  /// **'Ne recommande pas'**
  String get feedbackNotRecommends;

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

  /// No description provided for @premiumPaywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passez à Premium'**
  String get premiumPaywallTitle;

  /// No description provided for @tripDurationDays.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String tripDurationDays(int count);

  /// No description provided for @tripShareInvitedOnDate.
  ///
  /// In fr, this message translates to:
  /// **'Invité le {date}'**
  String tripShareInvitedOnDate(String date);

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

  /// No description provided for @nextTripCountdown.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days} jours'**
  String nextTripCountdown(int days);

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
  /// **'Bienvenue, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,\n{name}'**
  String homeGreetingMorning(String name);

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi,\n{name}'**
  String homeGreetingAfternoon(String name);

  /// No description provided for @homeGreetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir,\n{name}'**
  String homeGreetingEvening(String name);

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à voyager ?'**
  String get homeWelcomeTitle;

  /// No description provided for @homeSubtitleEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Quelle sera ta prochaine destination ?'**
  String get homeSubtitleEmpty;

  /// No description provided for @homeSubtitleOneTrip.
  ///
  /// In fr, this message translates to:
  /// **'1 voyage planifié'**
  String get homeSubtitleOneTrip;

  /// No description provided for @homeSubtitleTrips.
  ///
  /// In fr, this message translates to:
  /// **'{count} voyages planifiés'**
  String homeSubtitleTrips(int count);

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

  /// No description provided for @homeCtaAiOrManual.
  ///
  /// In fr, this message translates to:
  /// **'IA ou manuel'**
  String get homeCtaAiOrManual;

  /// No description provided for @homeCtaStartPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get homeCtaStartPlanning;

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

  /// No description provided for @datesChooseDatePlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get datesChooseDatePlaceholder;

  /// No description provided for @tripNightsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nuit} other{{count} nuits}}'**
  String tripNightsCount(int count);

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get days;

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

  /// No description provided for @editButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editButton;

  /// No description provided for @activityToValidate.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get activityToValidate;

  /// No description provided for @activityValidated.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get activityValidated;

  /// No description provided for @activityDisclaimerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA — vérifiez disponibilité et tarifs'**
  String get activityDisclaimerSubtitle;

  /// No description provided for @activityValidateConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier cette activité ?'**
  String get activityValidateConfirmTitle;

  /// No description provided for @activityValidateConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez ajuster le coût estimé si besoin.'**
  String get activityValidateConfirmMessage;

  /// No description provided for @activityValidateCostLabel.
  ///
  /// In fr, this message translates to:
  /// **'Coût réel (optionnel)'**
  String get activityValidateCostLabel;

  /// No description provided for @activityValidateConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get activityValidateConfirm;

  /// No description provided for @accommodationSearchHotels.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un hôtel'**
  String get accommodationSearchHotels;

  /// No description provided for @accommodationSearchHotelsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouver et comparer les prix'**
  String get accommodationSearchHotelsSubtitle;

  /// No description provided for @accommodationAddManually.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter manuellement'**
  String get accommodationAddManually;

  /// No description provided for @accommodationAddManuallySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Airbnb, auberge, hôtel, camping...'**
  String get accommodationAddManuallySubtitle;

  /// No description provided for @accommodationAiSuggestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations IA'**
  String get accommodationAiSuggestTitle;

  /// No description provided for @accommodationEstimatedPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix estimé'**
  String get accommodationEstimatedPrice;

  /// No description provided for @accommodationNights.
  ///
  /// In fr, this message translates to:
  /// **'nuit(s)'**
  String get accommodationNights;

  /// No description provided for @accommodationTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get accommodationTotal;

  /// No description provided for @accommodationSearchInArea.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans le quartier'**
  String get accommodationSearchInArea;

  /// No description provided for @accommodationTypeHotel.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel'**
  String get accommodationTypeHotel;

  /// No description provided for @accommodationTypeAirbnb.
  ///
  /// In fr, this message translates to:
  /// **'Airbnb'**
  String get accommodationTypeAirbnb;

  /// No description provided for @accommodationTypeHostel.
  ///
  /// In fr, this message translates to:
  /// **'Auberge'**
  String get accommodationTypeHostel;

  /// No description provided for @accommodationTypeCamping.
  ///
  /// In fr, this message translates to:
  /// **'Camping'**
  String get accommodationTypeCamping;

  /// No description provided for @accommodationTypeGuesthouse.
  ///
  /// In fr, this message translates to:
  /// **'Maison d\'hôtes'**
  String get accommodationTypeGuesthouse;

  /// No description provided for @accommodationTypeResort.
  ///
  /// In fr, this message translates to:
  /// **'Resort'**
  String get accommodationTypeResort;

  /// No description provided for @accommodationTypeOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get accommodationTypeOther;

  /// No description provided for @accommodationPricePerNight.
  ///
  /// In fr, this message translates to:
  /// **'Prix/nuit'**
  String get accommodationPricePerNight;

  /// No description provided for @accommodationAiDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA — vérifiez disponibilité et tarifs'**
  String get accommodationAiDisclaimer;

  /// No description provided for @budgetConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get budgetConfirmed;

  /// No description provided for @budgetForecasted.
  ///
  /// In fr, this message translates to:
  /// **'Prévisionnel'**
  String get budgetForecasted;

  /// No description provided for @budgetEstimateButton.
  ///
  /// In fr, this message translates to:
  /// **'Estimer mon budget'**
  String get budgetEstimateButton;

  /// No description provided for @budgetEstimateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Estimation du budget'**
  String get budgetEstimateTitle;

  /// No description provided for @budgetEstimateAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get budgetEstimateAccept;

  /// No description provided for @budgetEstimateModify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get budgetEstimateModify;

  /// No description provided for @budgetAccommodationPerNight.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement / nuit'**
  String get budgetAccommodationPerNight;

  /// No description provided for @budgetMealsPerDay.
  ///
  /// In fr, this message translates to:
  /// **'Repas / jour / personne'**
  String get budgetMealsPerDay;

  /// No description provided for @budgetLocalTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport local / jour'**
  String get budgetLocalTransport;

  /// No description provided for @budgetActivitiesTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total activités'**
  String get budgetActivitiesTotal;

  /// No description provided for @budgetTotalRange.
  ///
  /// In fr, this message translates to:
  /// **'{min} – {max} {currency}'**
  String budgetTotalRange(String min, String max, String currency);

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get statusConfirmed;

  /// No description provided for @statusForecasted.
  ///
  /// In fr, this message translates to:
  /// **'Prévisionnel'**
  String get statusForecasted;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get statusCompleted;

  /// No description provided for @emptyTransportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où volez-vous ?'**
  String get emptyTransportsTitle;

  /// No description provided for @emptyTransportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos vols pour organiser votre voyage'**
  String get emptyTransportsSubtitle;

  /// No description provided for @emptyAccommodationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où dormirez-vous ?'**
  String get emptyAccommodationsTitle;

  /// No description provided for @emptyAccommodationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos hôtels et logements'**
  String get emptyAccommodationsSubtitle;

  /// No description provided for @emptyFlightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à décoller ?'**
  String get emptyFlightsTitle;

  /// No description provided for @emptyFlightsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos vols pour suivre dates et horaires'**
  String get emptyFlightsSubtitle;

  /// No description provided for @noActivitiesThisDay.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu ce jour'**
  String get noActivitiesThisDay;

  /// No description provided for @emptyActivitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que découvrirez-vous ?'**
  String get emptyActivitiesTitle;

  /// No description provided for @emptyActivitiesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des activités pour planifier votre voyage'**
  String get emptyActivitiesSubtitle;

  /// No description provided for @emptyBaggageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Que faut-il emporter ?'**
  String get emptyBaggageTitle;

  /// No description provided for @emptyBaggageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des éléments à votre liste de bagages'**
  String get emptyBaggageSubtitle;

  /// No description provided for @baggageProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'{packed} / {total} prêts'**
  String baggageProgressLabel(int packed, int total);

  /// No description provided for @emptySharesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voyagez ensemble'**
  String get emptySharesTitle;

  /// No description provided for @emptySharesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez des compagnons pour collaborer sur ce voyage'**
  String get emptySharesSubtitle;

  /// No description provided for @budgetSeeAllExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes les dépenses'**
  String get budgetSeeAllExpenses;

  /// No description provided for @budgetOverBudgetBanner.
  ///
  /// In fr, this message translates to:
  /// **'Dépassement de {amount}'**
  String budgetOverBudgetBanner(String amount);

  /// No description provided for @emptyBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos dépenses'**
  String get emptyBudgetTitle;

  /// No description provided for @emptyBudgetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez vos dépenses et planifiez votre budget voyage'**
  String get emptyBudgetSubtitle;

  /// No description provided for @mapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get mapTitle;

  /// No description provided for @mapComingSoonSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre voyage sur une carte. Bientôt disponible.'**
  String get mapComingSoonSubtitle;

  /// No description provided for @mapComingSoonShort.
  ///
  /// In fr, this message translates to:
  /// **'Carte bientôt'**
  String get mapComingSoonShort;

  /// No description provided for @datesModeExact.
  ///
  /// In fr, this message translates to:
  /// **'Dates exactes'**
  String get datesModeExact;

  /// No description provided for @datesModeMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get datesModeMonth;

  /// No description provided for @datesModeFlexible.
  ///
  /// In fr, this message translates to:
  /// **'Flexible'**
  String get datesModeFlexible;

  /// No description provided for @datesFlexibleWeekend.
  ///
  /// In fr, this message translates to:
  /// **'Week-end'**
  String get datesFlexibleWeekend;

  /// No description provided for @datesFlexibleWeek.
  ///
  /// In fr, this message translates to:
  /// **'1 semaine'**
  String get datesFlexibleWeek;

  /// No description provided for @datesFlexibleTwoWeeks.
  ///
  /// In fr, this message translates to:
  /// **'2 semaines'**
  String get datesFlexibleTwoWeeks;

  /// No description provided for @datesFlexibleThreeWeeks.
  ///
  /// In fr, this message translates to:
  /// **'3 semaines'**
  String get datesFlexibleThreeWeeks;

  /// No description provided for @datesFlexibleWeekendDays.
  ///
  /// In fr, this message translates to:
  /// **'2-3 jours'**
  String get datesFlexibleWeekendDays;

  /// No description provided for @datesFlexibleWeekDays.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get datesFlexibleWeekDays;

  /// No description provided for @datesFlexibleTwoWeeksDays.
  ///
  /// In fr, this message translates to:
  /// **'14 jours'**
  String get datesFlexibleTwoWeeksDays;

  /// No description provided for @datesFlexibleThreeWeeksDays.
  ///
  /// In fr, this message translates to:
  /// **'21 jours'**
  String get datesFlexibleThreeWeeksDays;

  /// No description provided for @planTripStepDates.
  ///
  /// In fr, this message translates to:
  /// **'Quand partez-vous ?'**
  String get planTripStepDates;

  /// No description provided for @travelersLabel.
  ///
  /// In fr, this message translates to:
  /// **'VOYAGEURS'**
  String get travelersLabel;

  /// No description provided for @travelerCountLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 voyageur} other{{count} voyageurs}}'**
  String travelerCountLabel(int count);

  /// No description provided for @travelerTypeAdults.
  ///
  /// In fr, this message translates to:
  /// **'Adultes'**
  String get travelerTypeAdults;

  /// No description provided for @travelerTypeChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get travelerTypeChildren;

  /// No description provided for @travelerTypeBabies.
  ///
  /// In fr, this message translates to:
  /// **'Bébés'**
  String get travelerTypeBabies;

  /// No description provided for @travelerAgeAdultsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'13 ans et plus'**
  String get travelerAgeAdultsSubtitle;

  /// No description provided for @travelerAgeChildrenSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'3 à 12 ans'**
  String get travelerAgeChildrenSubtitle;

  /// No description provided for @travelerAgeBabiesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'0 à 2 ans'**
  String get travelerAgeBabiesSubtitle;

  /// No description provided for @travelerSegmentAdult.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 adulte} other{{count} adultes}}'**
  String travelerSegmentAdult(int count);

  /// No description provided for @travelerSegmentChild.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 enfant} other{{count} enfants}}'**
  String travelerSegmentChild(int count);

  /// No description provided for @travelerSegmentBaby.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 bébé} other{{count} bébés}}'**
  String travelerSegmentBaby(int count);

  /// No description provided for @planTripDurationDaysNights.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours · {nights} nuits'**
  String planTripDurationDaysNights(int days, int nights);

  /// No description provided for @budgetLabel.
  ///
  /// In fr, this message translates to:
  /// **'BUDGET'**
  String get budgetLabel;

  /// No description provided for @budgetPresetBackpacker.
  ///
  /// In fr, this message translates to:
  /// **'Routard'**
  String get budgetPresetBackpacker;

  /// No description provided for @budgetPresetBackpackerDesc.
  ///
  /// In fr, this message translates to:
  /// **'30–60 €/jour'**
  String get budgetPresetBackpackerDesc;

  /// No description provided for @budgetPresetComfortable.
  ///
  /// In fr, this message translates to:
  /// **'Confortable'**
  String get budgetPresetComfortable;

  /// No description provided for @budgetPresetComfortableDesc.
  ///
  /// In fr, this message translates to:
  /// **'80–150 €/jour'**
  String get budgetPresetComfortableDesc;

  /// No description provided for @budgetPresetPremium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get budgetPresetPremium;

  /// No description provided for @budgetPresetPremiumDesc.
  ///
  /// In fr, this message translates to:
  /// **'200–400 €/jour'**
  String get budgetPresetPremiumDesc;

  /// No description provided for @budgetPresetNoLimit.
  ///
  /// In fr, this message translates to:
  /// **'Sans limite'**
  String get budgetPresetNoLimit;

  /// No description provided for @budgetPresetNoLimitDesc.
  ///
  /// In fr, this message translates to:
  /// **'400+ €/jour'**
  String get budgetPresetNoLimitDesc;

  /// No description provided for @budgetEstimationLabel.
  ///
  /// In fr, this message translates to:
  /// **'TOTAL ESTIMÉ'**
  String get budgetEstimationLabel;

  /// No description provided for @budgetSkipLabel.
  ///
  /// In fr, this message translates to:
  /// **'Je verrai plus tard'**
  String get budgetSkipLabel;

  /// No description provided for @destinationSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'DESTINATION'**
  String get destinationSectionLabel;

  /// No description provided for @destinationPopularSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'POPULAIRES EN CE MOMENT'**
  String get destinationPopularSectionLabel;

  /// No description provided for @destinationOrSeparator.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get destinationOrSeparator;

  /// No description provided for @destinationNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get destinationNoResults;

  /// No description provided for @destinationAiLoading.
  ///
  /// In fr, this message translates to:
  /// **'Notre IA cherche pour vous...'**
  String get destinationAiLoading;

  /// No description provided for @stepAiProposals.
  ///
  /// In fr, this message translates to:
  /// **'Vos destinations'**
  String get stepAiProposals;

  /// No description provided for @chooseThisDestination.
  ///
  /// In fr, this message translates to:
  /// **'Choisir cette destination'**
  String get chooseThisDestination;

  /// No description provided for @swipeToDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Glissez pour découvrir →'**
  String get swipeToDiscover;

  /// No description provided for @aiProposalsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion disponible'**
  String get aiProposalsEmpty;

  /// No description provided for @aiProposalsEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Retournez en arrière et réessayez'**
  String get aiProposalsEmptySubtitle;

  /// No description provided for @aiBadgeLabel.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get aiBadgeLabel;

  /// No description provided for @stepGeneration.
  ///
  /// In fr, this message translates to:
  /// **'Génération...'**
  String get stepGeneration;

  /// No description provided for @generationTitle.
  ///
  /// In fr, this message translates to:
  /// **'GÉNÉRATION IA'**
  String get generationTitle;

  /// No description provided for @generationStepDestinations.
  ///
  /// In fr, this message translates to:
  /// **'Destinations'**
  String get generationStepDestinations;

  /// No description provided for @generationStepActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get generationStepActivities;

  /// No description provided for @generationStepAccommodations.
  ///
  /// In fr, this message translates to:
  /// **'Hébergements'**
  String get generationStepAccommodations;

  /// No description provided for @generationStepBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Bagages'**
  String get generationStepBaggage;

  /// No description provided for @generationStepBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get generationStepBudget;

  /// No description provided for @generationErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la génération'**
  String get generationErrorTitle;

  /// No description provided for @generationErrorSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get generationErrorSubtitle;

  /// No description provided for @generationTimeoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Temps dépassé'**
  String get generationTimeoutTitle;

  /// No description provided for @generationTimeoutSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'La génération prend plus de temps que prévu. Veuillez réessayer.'**
  String get generationTimeoutSubtitle;

  /// No description provided for @generationProgressLabel.
  ///
  /// In fr, this message translates to:
  /// **'{percent}%'**
  String generationProgressLabel(int percent);

  /// No description provided for @reviewCreateTrip.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon voyage'**
  String get reviewCreateTrip;

  /// No description provided for @reviewSeeOtherDestinations.
  ///
  /// In fr, this message translates to:
  /// **'Voir d\'autres destinations'**
  String get reviewSeeOtherDestinations;

  /// No description provided for @reviewSectionBudget.
  ///
  /// In fr, this message translates to:
  /// **'RÉPARTITION DU BUDGET'**
  String get reviewSectionBudget;

  /// No description provided for @reviewBudgetFlights.
  ///
  /// In fr, this message translates to:
  /// **'Vols'**
  String get reviewBudgetFlights;

  /// No description provided for @reviewBudgetAccommodation.
  ///
  /// In fr, this message translates to:
  /// **'Hébergement'**
  String get reviewBudgetAccommodation;

  /// No description provided for @reviewBudgetMeals.
  ///
  /// In fr, this message translates to:
  /// **'Repas'**
  String get reviewBudgetMeals;

  /// No description provided for @reviewBudgetTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get reviewBudgetTransport;

  /// No description provided for @reviewBudgetActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get reviewBudgetActivities;

  /// No description provided for @reviewBudgetOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get reviewBudgetOther;

  /// No description provided for @reviewBudgetTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get reviewBudgetTotal;

  /// No description provided for @reviewBudgetEstimationPrefix.
  ///
  /// In fr, this message translates to:
  /// **'estimation'**
  String get reviewBudgetEstimationPrefix;

  /// No description provided for @reviewBudgetUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Estimation du budget indisponible'**
  String get reviewBudgetUnavailable;

  /// No description provided for @reviewSourceVerified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get reviewSourceVerified;

  /// No description provided for @reviewSourceEstimated.
  ///
  /// In fr, this message translates to:
  /// **'Estimé'**
  String get reviewSourceEstimated;

  /// No description provided for @reviewPriceEur.
  ///
  /// In fr, this message translates to:
  /// **'{amount} EUR'**
  String reviewPriceEur(String amount);

  /// No description provided for @reviewHighlightsLabel.
  ///
  /// In fr, this message translates to:
  /// **'TEMPS FORTS'**
  String get reviewHighlightsLabel;

  /// No description provided for @reviewSectionDates.
  ///
  /// In fr, this message translates to:
  /// **'DATES'**
  String get reviewSectionDates;

  /// No description provided for @reviewDatesSuggested.
  ///
  /// In fr, this message translates to:
  /// **'Dates suggérées — appuyez pour ajuster'**
  String get reviewDatesSuggested;

  /// No description provided for @reviewEssentialReason.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi : {reason}'**
  String reviewEssentialReason(String reason);

  /// No description provided for @reviewNoActivities.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité prévue'**
  String get reviewNoActivities;

  /// No description provided for @reviewTabOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get reviewTabOverview;

  /// No description provided for @reviewTabFlights.
  ///
  /// In fr, this message translates to:
  /// **'Vols'**
  String get reviewTabFlights;

  /// No description provided for @reviewTabHotel.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel'**
  String get reviewTabHotel;

  /// No description provided for @reviewTabItinerary.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get reviewTabItinerary;

  /// No description provided for @reviewTabEssentials.
  ///
  /// In fr, this message translates to:
  /// **'Essentiels'**
  String get reviewTabEssentials;

  /// No description provided for @reviewTabBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get reviewTabBudget;

  /// No description provided for @reviewTimelineFlight.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get reviewTimelineFlight;

  /// No description provided for @reviewTimelineActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get reviewTimelineActivity;

  /// No description provided for @reviewTimelineCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Check-in'**
  String get reviewTimelineCheckIn;

  /// No description provided for @reviewTimelineCheckOut.
  ///
  /// In fr, this message translates to:
  /// **'Check-out'**
  String get reviewTimelineCheckOut;

  /// No description provided for @reviewFlightOutbound.
  ///
  /// In fr, this message translates to:
  /// **'Aller'**
  String get reviewFlightOutbound;

  /// No description provided for @reviewFlightReturn.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get reviewFlightReturn;

  /// No description provided for @reviewFlightDeparture.
  ///
  /// In fr, this message translates to:
  /// **'Départ'**
  String get reviewFlightDeparture;

  /// No description provided for @reviewFlightArrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get reviewFlightArrival;

  /// No description provided for @reviewHotelCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Check-in'**
  String get reviewHotelCheckIn;

  /// No description provided for @reviewHotelCheckOut.
  ///
  /// In fr, this message translates to:
  /// **'Check-out'**
  String get reviewHotelCheckOut;

  /// No description provided for @reviewHotelNights.
  ///
  /// In fr, this message translates to:
  /// **'Nuits'**
  String get reviewHotelNights;

  /// No description provided for @reviewHotelPerNight.
  ///
  /// In fr, this message translates to:
  /// **'Par nuit'**
  String get reviewHotelPerNight;

  /// No description provided for @reviewSummaryLine.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours à {city} pour {travelers}'**
  String reviewSummaryLine(int days, String city, String travelers);

  /// No description provided for @reviewSummaryTravelers.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 voyageur} other{{count} voyageurs}}'**
  String reviewSummaryTravelers(int count);

  /// No description provided for @reviewJourneyHeader.
  ///
  /// In fr, this message translates to:
  /// **'Votre voyage'**
  String get reviewJourneyHeader;

  /// No description provided for @reviewDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jour {day} · {date}'**
  String reviewDayTitle(int day, String date);

  /// No description provided for @reviewDayFree.
  ///
  /// In fr, this message translates to:
  /// **'Une journée libre'**
  String get reviewDayFree;

  /// No description provided for @reviewFlightDurationHm.
  ///
  /// In fr, this message translates to:
  /// **'{hours}h{minutes}'**
  String reviewFlightDurationHm(int hours, String minutes);

  /// No description provided for @reviewHotelArrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée'**
  String get reviewHotelArrival;

  /// No description provided for @reviewHotelStayNights.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 nuit} other{{count} nuits}}'**
  String reviewHotelStayNights(int count);

  /// No description provided for @reviewBudgetHeader.
  ///
  /// In fr, this message translates to:
  /// **'Le budget'**
  String get reviewBudgetHeader;

  /// No description provided for @reviewBudgetPerPerson.
  ///
  /// In fr, this message translates to:
  /// **'{amount} par voyageur'**
  String reviewBudgetPerPerson(String amount);

  /// No description provided for @reviewDecisionHeader.
  ///
  /// In fr, this message translates to:
  /// **'À vous de choisir'**
  String get reviewDecisionHeader;

  /// No description provided for @reviewDecisionPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Planifier ce voyage'**
  String get reviewDecisionPrimary;

  /// No description provided for @homeActiveTripTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre voyage à {destination}'**
  String homeActiveTripTitle(String destination);

  /// No description provided for @homeActiveTripDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour {current} sur {total}'**
  String homeActiveTripDay(int current, int total);

  /// No description provided for @homeTodayActivities.
  ///
  /// In fr, this message translates to:
  /// **'Programme du jour'**
  String get homeTodayActivities;

  /// No description provided for @homeNoActivitiesToday.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité prévue aujourd\'hui'**
  String get homeNoActivitiesToday;

  /// No description provided for @tripCardNoDestination.
  ///
  /// In fr, this message translates to:
  /// **'Pas de destination'**
  String get tripCardNoDestination;

  /// No description provided for @tripCardNoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voyage sans titre'**
  String get tripCardNoTitle;

  /// No description provided for @activeTripsAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Toute la journée'**
  String get activeTripsAllDay;

  /// No description provided for @activeTripsTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get activeTripsTomorrow;

  /// No description provided for @activeTripsTomorrowCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 activité} other{{count} activités}}'**
  String activeTripsTomorrowCount(int count);

  /// No description provided for @activeTripsQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get activeTripsQuickActions;

  /// No description provided for @completionDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates'**
  String get completionDates;

  /// No description provided for @completionFlights.
  ///
  /// In fr, this message translates to:
  /// **'Vols'**
  String get completionFlights;

  /// No description provided for @completionAccommodation.
  ///
  /// In fr, this message translates to:
  /// **'Hôtels'**
  String get completionAccommodation;

  /// No description provided for @completionActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get completionActivities;

  /// No description provided for @completionBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Bagages'**
  String get completionBaggage;

  /// No description provided for @completionBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get completionBudget;

  /// No description provided for @tripDetailQuickFlights.
  ///
  /// In fr, this message translates to:
  /// **'Vols'**
  String get tripDetailQuickFlights;

  /// No description provided for @tripDetailQuickActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get tripDetailQuickActivities;

  /// No description provided for @tripDetailQuickAddFlight.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter vol'**
  String get tripDetailQuickAddFlight;

  /// No description provided for @tripDetailQuickAddHotel.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter hôtel'**
  String get tripDetailQuickAddHotel;

  /// No description provided for @tripDetailQuickAddActivity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter activité'**
  String get tripDetailQuickAddActivity;

  /// No description provided for @tripDetailQuickExpense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get tripDetailQuickExpense;

  /// No description provided for @tripDetailQuickBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Bagages'**
  String get tripDetailQuickBaggage;

  /// No description provided for @tripDetailQuickMemories.
  ///
  /// In fr, this message translates to:
  /// **'Souvenirs'**
  String get tripDetailQuickMemories;

  /// No description provided for @timelineSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get timelineSectionTitle;

  /// No description provided for @timelineMorning.
  ///
  /// In fr, this message translates to:
  /// **'Matin'**
  String get timelineMorning;

  /// No description provided for @timelineAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Après-midi'**
  String get timelineAfternoon;

  /// No description provided for @timelineEvening.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get timelineEvening;

  /// No description provided for @timelineEmptyDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité'**
  String get timelineEmptyDayTitle;

  /// No description provided for @timelineEmptyDaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez-en ou demandez à l\'IA de vous suggérer des idées'**
  String get timelineEmptyDaySubtitle;

  /// No description provided for @timelineValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get timelineValidate;

  /// No description provided for @timelineReject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get timelineReject;

  /// No description provided for @flightStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get flightStatusConfirmed;

  /// No description provided for @flightStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get flightStatusPending;

  /// No description provided for @flightsSectionEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où allez-vous ?'**
  String get flightsSectionEmptyTitle;

  /// No description provided for @flightsSectionEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos vols pour organiser votre voyage'**
  String get flightsSectionEmptySubtitle;

  /// No description provided for @flightsSectionSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les vols ({count})'**
  String flightsSectionSeeAll(int count);

  /// No description provided for @flightsSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vols'**
  String get flightsSectionTitle;

  /// No description provided for @accommodationSectionSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les hébergements ({count})'**
  String accommodationSectionSeeAll(int count);

  /// No description provided for @accommodationStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get accommodationStatusConfirmed;

  /// No description provided for @accommodationStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get accommodationStatusPending;

  /// No description provided for @baggageSectionSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les éléments ({count})'**
  String baggageSectionSeeAll(int count);

  /// No description provided for @baggageSectionAddItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get baggageSectionAddItem;

  /// No description provided for @baggageSectionAddItemSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre liste'**
  String get baggageSectionAddItemSubtitle;

  /// No description provided for @baggageSectionAiSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get baggageSectionAiSuggest;

  /// No description provided for @baggageSectionAiSuggestSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Laissez l\'IA vous aider'**
  String get baggageSectionAiSuggestSubtitle;

  /// No description provided for @budgetEstimateOptionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Laissez l\'IA vous suggerer un budget'**
  String get budgetEstimateOptionSubtitle;

  /// No description provided for @budgetAddExpenseSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suivez une depense prevue ou reelle'**
  String get budgetAddExpenseSubtitle;

  /// No description provided for @budgetManageAll.
  ///
  /// In fr, this message translates to:
  /// **'Gerer le budget'**
  String get budgetManageAll;

  /// No description provided for @budgetCategoryBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Repartition'**
  String get budgetCategoryBreakdown;

  /// No description provided for @sharingSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage'**
  String get sharingSectionTitle;

  /// No description provided for @sharingSectionEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre voyage'**
  String get sharingSectionEmptyTitle;

  /// No description provided for @sharingSectionEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invitez vos proches a suivre votre voyage'**
  String get sharingSectionEmptySubtitle;

  /// No description provided for @sharingSectionInvite.
  ///
  /// In fr, this message translates to:
  /// **'Inviter quelqu\'un'**
  String get sharingSectionInvite;

  /// No description provided for @sharingSectionInviteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre voyage avec d\'autres'**
  String get sharingSectionInviteSubtitle;

  /// No description provided for @sharingSectionSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les membres ({count})'**
  String sharingSectionSeeAll(int count);

  /// No description provided for @sharingSectionOwner.
  ///
  /// In fr, this message translates to:
  /// **'Proprietaire'**
  String get sharingSectionOwner;

  /// No description provided for @sharingSectionViewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get sharingSectionViewer;

  /// No description provided for @sharingSectionYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get sharingSectionYou;

  /// No description provided for @timelineInMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Dans {minutes} min'**
  String timelineInMinutes(int minutes);

  /// No description provided for @timelineNow.
  ///
  /// In fr, this message translates to:
  /// **'Maintenant'**
  String get timelineNow;

  /// No description provided for @timelineInProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get timelineInProgress;

  /// No description provided for @timelineRemainingMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min restantes'**
  String timelineRemainingMinutes(int minutes);

  /// No description provided for @timelineNavigate.
  ///
  /// In fr, this message translates to:
  /// **'Naviguer'**
  String get timelineNavigate;

  /// No description provided for @timelineChooseMapApp.
  ///
  /// In fr, this message translates to:
  /// **'Choisir l\'application'**
  String get timelineChooseMapApp;

  /// No description provided for @timelineAppleMaps.
  ///
  /// In fr, this message translates to:
  /// **'Apple Plans'**
  String get timelineAppleMaps;

  /// No description provided for @timelineGoogleMaps.
  ///
  /// In fr, this message translates to:
  /// **'Google Maps'**
  String get timelineGoogleMaps;

  /// No description provided for @activeTripsTomorrowLastDay.
  ///
  /// In fr, this message translates to:
  /// **'Dernier jour de voyage'**
  String get activeTripsTomorrowLastDay;

  /// No description provided for @activeTripsTomorrowShowAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout ({count})'**
  String activeTripsTomorrowShowAll(int count);

  /// No description provided for @activeTripsTomorrowCollapse.
  ///
  /// In fr, this message translates to:
  /// **'Voir moins'**
  String get activeTripsTomorrowCollapse;

  /// No description provided for @qaSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Programme'**
  String get qaSchedule;

  /// No description provided for @qaWeather.
  ///
  /// In fr, this message translates to:
  /// **'Meteo'**
  String get qaWeather;

  /// No description provided for @qaCheckOut.
  ///
  /// In fr, this message translates to:
  /// **'Check-out'**
  String get qaCheckOut;

  /// No description provided for @qaNavigate.
  ///
  /// In fr, this message translates to:
  /// **'Naviguer'**
  String get qaNavigate;

  /// No description provided for @qaExpense.
  ///
  /// In fr, this message translates to:
  /// **'Depense'**
  String get qaExpense;

  /// No description provided for @qaPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get qaPhoto;

  /// No description provided for @qaNextActivity.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine'**
  String get qaNextActivity;

  /// No description provided for @qaAiSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Idee IA'**
  String get qaAiSuggestion;

  /// No description provided for @qaMap.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get qaMap;

  /// No description provided for @qaTodayExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get qaTodayExpenses;

  /// No description provided for @qaTomorrow.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get qaTomorrow;

  /// No description provided for @qaBudget.
  ///
  /// In fr, this message translates to:
  /// **'Budget'**
  String get qaBudget;

  /// No description provided for @qaQuickExpenseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Depense rapide'**
  String get qaQuickExpenseTitle;

  /// No description provided for @qaQuickExpenseNote.
  ///
  /// In fr, this message translates to:
  /// **'Note (optionnel)'**
  String get qaQuickExpenseNote;

  /// No description provided for @qaQuickExpenseAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get qaQuickExpenseAmount;

  /// No description provided for @qaQuickExpenseAmountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Montant requis'**
  String get qaQuickExpenseAmountRequired;

  /// No description provided for @qaQuickExpenseInvalidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant invalide'**
  String get qaQuickExpenseInvalidAmount;

  /// No description provided for @qaCategoryFood.
  ///
  /// In fr, this message translates to:
  /// **'Repas'**
  String get qaCategoryFood;

  /// No description provided for @qaCategoryTransport.
  ///
  /// In fr, this message translates to:
  /// **'Transport'**
  String get qaCategoryTransport;

  /// No description provided for @qaCategoryActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activite'**
  String get qaCategoryActivity;

  /// No description provided for @qaCategoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get qaCategoryOther;

  /// No description provided for @postTripDetectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Voyage terminé !'**
  String get postTripDetectionTitle;

  /// No description provided for @postTripDetectionMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre voyage à {destination} est terminé. Voulez-vous le marquer comme complété ?'**
  String postTripDetectionMessage(String destination);

  /// No description provided for @postTripDetectionConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, terminer'**
  String get postTripDetectionConfirm;

  /// No description provided for @postTripDetectionRemindLater.
  ///
  /// In fr, this message translates to:
  /// **'Me rappeler plus tard'**
  String get postTripDetectionRemindLater;

  /// No description provided for @postTripSouvenirsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souvenirs'**
  String get postTripSouvenirsTitle;

  /// No description provided for @postTripDaysCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours d\'aventure'**
  String postTripDaysCount(int count);

  /// No description provided for @postTripActivitiesCompleted.
  ///
  /// In fr, this message translates to:
  /// **'{completed} sur {total} activités'**
  String postTripActivitiesCompleted(int completed, int total);

  /// No description provided for @postTripBudgetSpent.
  ///
  /// In fr, this message translates to:
  /// **'{amount} dépensés'**
  String postTripBudgetSpent(String amount);

  /// No description provided for @postTripCategoriesExplored.
  ///
  /// In fr, this message translates to:
  /// **'{count} catégories explorées'**
  String postTripCategoriesExplored(int count);

  /// No description provided for @postTripGiveReview.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience'**
  String get postTripGiveReview;

  /// No description provided for @postTripPlanNext.
  ///
  /// In fr, this message translates to:
  /// **'Planifier votre prochain voyage'**
  String get postTripPlanNext;

  /// No description provided for @feedbackAiRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Notez l\'expérience de planification IA'**
  String get feedbackAiRatingLabel;

  /// No description provided for @editTripTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le nom du voyage'**
  String get editTripTitle;

  /// No description provided for @editTripDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates du voyage'**
  String get editTripDates;

  /// No description provided for @editTripStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get editTripStartDate;

  /// No description provided for @editTripEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get editTripEndDate;

  /// No description provided for @editTripTravelers.
  ///
  /// In fr, this message translates to:
  /// **'Voyageurs'**
  String get editTripTravelers;

  /// No description provided for @activitiesOutOfRangeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Activités hors période'**
  String get activitiesOutOfRangeTitle;

  /// No description provided for @activitiesOutOfRangeMessage.
  ///
  /// In fr, this message translates to:
  /// **'{count} activités sont hors de la nouvelle période'**
  String activitiesOutOfRangeMessage(int count);

  /// No description provided for @cannotFinalizeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de finaliser'**
  String get cannotFinalizeTitle;

  /// No description provided for @cannotFinalizeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une destination et des dates'**
  String get cannotFinalizeMessage;

  /// No description provided for @finalizeMissingDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination manquante'**
  String get finalizeMissingDestination;

  /// No description provided for @finalizeMissingDates.
  ///
  /// In fr, this message translates to:
  /// **'Dates manquantes'**
  String get finalizeMissingDates;

  /// No description provided for @routeSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get routeSectionLabel;

  /// No description provided for @scheduleSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get scheduleSectionLabel;

  /// No description provided for @detailsSectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get detailsSectionLabel;

  /// No description provided for @airportsMustDiffer.
  ///
  /// In fr, this message translates to:
  /// **'Les aéroports de départ et d\'arrivée doivent être différents'**
  String get airportsMustDiffer;

  /// No description provided for @arrivalMustBeAfterDeparture.
  ///
  /// In fr, this message translates to:
  /// **'L\'arrivée doit être après le départ'**
  String get arrivalMustBeAfterDeparture;

  /// No description provided for @accommodationEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'hébergement'**
  String get accommodationEditTitle;

  /// No description provided for @accommodationSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get accommodationSaveButton;

  /// No description provided for @accommodationAddressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get accommodationAddressLabel;

  /// No description provided for @accommodationReferenceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence de réservation'**
  String get accommodationReferenceLabel;

  /// No description provided for @accommodationCheckOutBeforeCheckIn.
  ///
  /// In fr, this message translates to:
  /// **'Le check-out doit être après le check-in'**
  String get accommodationCheckOutBeforeCheckIn;

  /// No description provided for @accommodationCheckInTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure d\'arrivée'**
  String get accommodationCheckInTimeLabel;

  /// No description provided for @accommodationCheckOutTimeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Heure de départ'**
  String get accommodationCheckOutTimeLabel;

  /// No description provided for @accommodationSelectHotel.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get accommodationSelectHotel;

  /// No description provided for @accommodationPerNight.
  ///
  /// In fr, this message translates to:
  /// **'/nuit'**
  String get accommodationPerNight;

  /// No description provided for @accommodationNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun hôtel trouvé'**
  String get accommodationNoResults;

  /// No description provided for @baggageAllPacked.
  ///
  /// In fr, this message translates to:
  /// **'Tout est prêt !'**
  String get baggageAllPacked;

  /// No description provided for @baggageAllPackedSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes prêt pour votre voyage !'**
  String get baggageAllPackedSubtitle;

  /// No description provided for @baggageSwipeToDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get baggageSwipeToDelete;

  /// No description provided for @activityBatchCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} à valider'**
  String activityBatchCount(int count);

  /// No description provided for @activityValidateAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout valider'**
  String get activityValidateAll;

  /// No description provided for @activityReviewOneByOne.
  ///
  /// In fr, this message translates to:
  /// **'Revoir un par un'**
  String get activityReviewOneByOne;

  /// No description provided for @activityBatchValidated.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les activités validées !'**
  String get activityBatchValidated;

  /// No description provided for @categoryCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get categoryCulture;

  /// No description provided for @categoryNature.
  ///
  /// In fr, this message translates to:
  /// **'Nature'**
  String get categoryNature;

  /// No description provided for @categoryFoodDrink.
  ///
  /// In fr, this message translates to:
  /// **'Gastronomie'**
  String get categoryFoodDrink;

  /// No description provided for @categorySport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get categorySport;

  /// No description provided for @categoryShopping.
  ///
  /// In fr, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryNightlife.
  ///
  /// In fr, this message translates to:
  /// **'Vie nocturne'**
  String get categoryNightlife;

  /// No description provided for @categoryRelaxation.
  ///
  /// In fr, this message translates to:
  /// **'Détente'**
  String get categoryRelaxation;

  /// No description provided for @categoryOtherActivity.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get categoryOtherActivity;

  /// No description provided for @activityMovedToDay.
  ///
  /// In fr, this message translates to:
  /// **'Activité déplacée au jour {day}'**
  String activityMovedToDay(int day);

  /// No description provided for @timelineGetSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir des suggestions IA'**
  String get timelineGetSuggestions;

  /// No description provided for @timelineSuggestionsForDay.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions pour cette journée'**
  String get timelineSuggestionsForDay;

  /// No description provided for @timelineAddSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à l\'itinéraire'**
  String get timelineAddSuggestion;

  /// No description provided for @addActivityManually.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter manuellement'**
  String get addActivityManually;

  /// No description provided for @shareInviteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inviter au voyage'**
  String get shareInviteTitle;

  /// No description provided for @shareInviteEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email'**
  String get shareInviteEmailLabel;

  /// No description provided for @shareInviteEmailHint.
  ///
  /// In fr, this message translates to:
  /// **'utilisateur@exemple.com'**
  String get shareInviteEmailHint;

  /// No description provided for @shareInviteEmailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get shareInviteEmailRequired;

  /// No description provided for @shareInviteEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'email invalide'**
  String get shareInviteEmailInvalid;

  /// No description provided for @shareInviteMessageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Message (optionnel)'**
  String get shareInviteMessageLabel;

  /// No description provided for @shareInviteMessageHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un message personnel...'**
  String get shareInviteMessageHint;

  /// No description provided for @shareInviteSendButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer l\'invitation'**
  String get shareInviteSendButton;

  /// No description provided for @shareRoleViewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecteur'**
  String get shareRoleViewer;

  /// No description provided for @shareRoleEditor.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur'**
  String get shareRoleEditor;

  /// No description provided for @shareInvitePendingMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne n\'est pas encore inscrite. Elle aura accès en s\'inscrivant.'**
  String get shareInvitePendingMessage;

  /// No description provided for @shareInviteLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien d\'invitation copié'**
  String get shareInviteLinkCopied;

  /// No description provided for @shareErrorUserNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Cette personne doit d\'abord créer un compte'**
  String get shareErrorUserNotFound;

  /// No description provided for @shareErrorAlreadyShared.
  ///
  /// In fr, this message translates to:
  /// **'Déjà partagé avec cette personne'**
  String get shareErrorAlreadyShared;

  /// No description provided for @shareErrorSelfShare.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas partager un voyage avec vous-même'**
  String get shareErrorSelfShare;

  /// No description provided for @shareRevokeConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'accès'**
  String get shareRevokeConfirmTitle;

  /// No description provided for @shareRevokeConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'accès de {name} ?'**
  String shareRevokeConfirmMessage(String name);

  /// No description provided for @viewerBadgeReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get viewerBadgeReadOnly;

  /// No description provided for @shareInviteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Invitation envoyée'**
  String get shareInviteSuccess;

  /// No description provided for @filterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filterTitle;

  /// No description provided for @filterPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get filterPrice;

  /// No description provided for @filterPriceLowest.
  ///
  /// In fr, this message translates to:
  /// **'Prix le plus bas'**
  String get filterPriceLowest;

  /// No description provided for @filterPriceHighest.
  ///
  /// In fr, this message translates to:
  /// **'Prix le plus haut'**
  String get filterPriceHighest;

  /// No description provided for @filterAirline.
  ///
  /// In fr, this message translates to:
  /// **'Compagnie aérienne'**
  String get filterAirline;

  /// No description provided for @filterNoAirlines.
  ///
  /// In fr, this message translates to:
  /// **'Aucune compagnie disponible'**
  String get filterNoAirlines;

  /// No description provided for @filterAllAirlines.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAllAirlines;

  /// No description provided for @filterBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Bagages'**
  String get filterBaggage;

  /// No description provided for @filterDepartureTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de départ'**
  String get filterDepartureTime;

  /// No description provided for @filterBefore.
  ///
  /// In fr, this message translates to:
  /// **'Avant'**
  String get filterBefore;

  /// No description provided for @filterAfter.
  ///
  /// In fr, this message translates to:
  /// **'Après'**
  String get filterAfter;

  /// No description provided for @filterApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get filterApply;

  /// No description provided for @doneButton.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get doneButton;

  /// No description provided for @contextMenuView.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get contextMenuView;

  /// No description provided for @contextMenuShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get contextMenuShare;

  /// No description provided for @contextMenuArchive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get contextMenuArchive;

  /// No description provided for @contextMenuEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get contextMenuEdit;

  /// No description provided for @contextMenuValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get contextMenuValidate;

  /// No description provided for @contextMenuDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get contextMenuDelete;

  /// No description provided for @contextMenuMoveToDay.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers un autre jour'**
  String get contextMenuMoveToDay;

  /// No description provided for @contextMenuDayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Jour {day}'**
  String contextMenuDayLabel(int day);

  /// No description provided for @tripCardSemanticLabel.
  ///
  /// In fr, this message translates to:
  /// **'{destination}, {dateRange}, {status}'**
  String tripCardSemanticLabel(
    String destination,
    String dateRange,
    String status,
  );

  /// No description provided for @tripCoverImageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture de {destination}'**
  String tripCoverImageLabel(String destination);

  /// No description provided for @activityCardSemanticLabel.
  ///
  /// In fr, this message translates to:
  /// **'{title}, {time}, {location}, {status}'**
  String activityCardSemanticLabel(
    String title,
    String time,
    String location,
    String status,
  );

  /// No description provided for @timelineActivitySemanticLabel.
  ///
  /// In fr, this message translates to:
  /// **'{title}, {time}, {location}'**
  String timelineActivitySemanticLabel(
    String title,
    String time,
    String location,
  );

  /// No description provided for @addTripTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un voyage'**
  String get addTripTooltip;

  /// No description provided for @addActivityTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une activite'**
  String get addActivityTooltip;

  /// No description provided for @addAccommodationTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un hebergement'**
  String get addAccommodationTooltip;

  /// No description provided for @addTransportTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un transport'**
  String get addTransportTooltip;

  /// No description provided for @addExpenseTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une depense'**
  String get addExpenseTooltip;

  /// No description provided for @addBaggageItemTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un element'**
  String get addBaggageItemTooltip;

  /// No description provided for @addFlightTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un vol'**
  String get addFlightTooltip;

  /// No description provided for @sharesAddMemberTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get sharesAddMemberTooltip;

  /// No description provided for @myTripFallback.
  ///
  /// In fr, this message translates to:
  /// **'Mon voyage'**
  String get myTripFallback;

  /// No description provided for @completionSegmentsSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Encore à compléter'**
  String get completionSegmentsSheetTitle;

  /// No description provided for @shareTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get shareTooltip;

  /// No description provided for @backTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get backTooltip;

  /// No description provided for @deleteFlightTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le vol'**
  String get deleteFlightTooltip;

  /// No description provided for @editFlight.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le vol'**
  String get editFlight;

  /// No description provided for @editFlightTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier ce vol'**
  String get editFlightTooltip;

  /// No description provided for @multiDestResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats par segment'**
  String get multiDestResults;

  /// No description provided for @segmentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Segment {index}'**
  String segmentLabel(int index);

  /// No description provided for @deleteAccommodationTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'hebergement'**
  String get deleteAccommodationTooltip;

  /// No description provided for @removeAccessTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'acces'**
  String get removeAccessTooltip;

  /// No description provided for @inviteTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get inviteTooltip;

  /// No description provided for @acceptSuggestionTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Accepter la suggestion'**
  String get acceptSuggestionTooltip;

  /// No description provided for @dismissSuggestionTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer la suggestion'**
  String get dismissSuggestionTooltip;

  /// No description provided for @decreaseQuantityTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Diminuer la quantite'**
  String get decreaseQuantityTooltip;

  /// No description provided for @increaseQuantityTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter la quantite'**
  String get increaseQuantityTooltip;

  /// No description provided for @starRatingTooltip.
  ///
  /// In fr, this message translates to:
  /// **'{current} sur {total} etoiles'**
  String starRatingTooltip(int current, int total);

  /// No description provided for @tabActivityWithBadge.
  ///
  /// In fr, this message translates to:
  /// **'Activite, {count} notifications'**
  String tabActivityWithBadge(int count);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Si cette adresse existe, un lien de réinitialisation a été envoyé. Vérifiez votre boîte de réception.'**
  String get forgotPasswordSuccess;

  /// No description provided for @deleteAccountButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer mon compte'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte ?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cela supprimera définitivement votre compte et toutes les données associées. Cette action est irréversible.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteAccountConfirmAction;

  /// No description provided for @bookFlight.
  ///
  /// In fr, this message translates to:
  /// **'Réserver ce vol'**
  String get bookFlight;

  /// No description provided for @weatherSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weatherSheetTitle;

  /// No description provided for @weatherSheetTemperature.
  ///
  /// In fr, this message translates to:
  /// **'Température'**
  String get weatherSheetTemperature;

  /// No description provided for @weatherSheetRainProbability.
  ///
  /// In fr, this message translates to:
  /// **'Probabilité de pluie'**
  String get weatherSheetRainProbability;

  /// No description provided for @weatherSheetUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Données météo indisponibles'**
  String get weatherSheetUnavailable;

  /// No description provided for @photoLaunchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'appareil photo'**
  String get photoLaunchFailed;

  /// No description provided for @mapLocationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Lieux du voyage'**
  String get mapLocationsTitle;

  /// No description provided for @mapNoLocations.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lieu ajouté'**
  String get mapNoLocations;

  /// No description provided for @mapDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get mapDestination;

  /// No description provided for @mapActivities.
  ///
  /// In fr, this message translates to:
  /// **'Activités'**
  String get mapActivities;

  /// No description provided for @mapAccommodations.
  ///
  /// In fr, this message translates to:
  /// **'Hébergements'**
  String get mapAccommodations;

  /// No description provided for @originCityLabel.
  ///
  /// In fr, this message translates to:
  /// **'VILLE DE DÉPART'**
  String get originCityLabel;

  /// No description provided for @originCityPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Votre ville'**
  String get originCityPlaceholder;

  /// No description provided for @originCityHint.
  ///
  /// In fr, this message translates to:
  /// **'D\'où partez-vous ?'**
  String get originCityHint;

  /// No description provided for @notFoundTitle.
  ///
  /// In fr, this message translates to:
  /// **'Page introuvable'**
  String get notFoundTitle;

  /// No description provided for @notFoundSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'La page que vous recherchez n\'existe pas ou a été déplacée.'**
  String get notFoundSubtitle;

  /// No description provided for @notFoundCta.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get notFoundCta;

  /// No description provided for @subpageHeroBadgeViewer.
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule'**
  String get subpageHeroBadgeViewer;

  /// No description provided for @subpageHeroBadgeCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get subpageHeroBadgeCompleted;

  /// No description provided for @blankActivitiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton itinéraire est vide'**
  String get blankActivitiesTitle;

  /// No description provided for @blankActivitiesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifie ce qui rendra ce voyage mémorable.'**
  String get blankActivitiesSubtitle;

  /// No description provided for @blankActivitiesPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la première activité'**
  String get blankActivitiesPrimary;

  /// No description provided for @blankActivitiesSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Laisser l’IA composer une journée'**
  String get blankActivitiesSecondary;

  /// No description provided for @blankActivitiesNoDatesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Avant de planifier…'**
  String get blankActivitiesNoDatesTitle;

  /// No description provided for @blankActivitiesNoDatesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis les dates du voyage d’abord — on saura alors quand planifier.'**
  String get blankActivitiesNoDatesSubtitle;

  /// No description provided for @blankActivitiesNoDatesPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l’aperçu'**
  String get blankActivitiesNoDatesPrimary;

  /// No description provided for @activitiesHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 activité} other{{count} activités}} · {days, plural, =1{1 jour} other{{days} jours}}'**
  String activitiesHeroMeta(int count, int days);

  /// No description provided for @blankTransportsTitle.
  ///
  /// In fr, this message translates to:
  /// **'À vous les airs.'**
  String get blankTransportsTitle;

  /// No description provided for @blankTransportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Aller, retour, vols internes — on garde tout sous la main.'**
  String get blankTransportsSubtitle;

  /// No description provided for @blankTransportsPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le premier vol'**
  String get blankTransportsPrimary;

  /// No description provided for @transportsHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 vol} other{{count} vols}}'**
  String transportsHeroMeta(int count);

  /// No description provided for @blankAccommodationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Où poser vos valises ?'**
  String get blankAccommodationsTitle;

  /// No description provided for @blankAccommodationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel, Airbnb, canapé d’ami — note-le ici pour les rappels de check-in.'**
  String get blankAccommodationsSubtitle;

  /// No description provided for @blankAccommodationsPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un hébergement'**
  String get blankAccommodationsPrimary;

  /// No description provided for @blankAccommodationsSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get blankAccommodationsSecondary;

  /// No description provided for @accommodationsHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 hébergement} other{{count} hébergements}} · {nights, plural, =1{1 nuit} other{{nights} nuits}}'**
  String accommodationsHeroMeta(int count, int nights);

  /// No description provided for @blankBaggageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Faire sa valise, ça commence par un objet.'**
  String get blankBaggageTitle;

  /// No description provided for @blankBaggageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Construis la checklist que tu cocheras avant chaque départ.'**
  String get blankBaggageSubtitle;

  /// No description provided for @blankBaggagePrimary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le premier objet'**
  String get blankBaggagePrimary;

  /// No description provided for @blankBaggageSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions pour ce voyage'**
  String get blankBaggageSecondary;

  /// No description provided for @baggageHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{packed, plural, =0{rien de prêt} other{{packed} sur {total} prêts}}'**
  String baggageHeroMeta(int packed, int total);

  /// No description provided for @blankBudgetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel budget pour ce voyage ?'**
  String get blankBudgetTitle;

  /// No description provided for @blankBudgetSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Fixe un budget, suis les dépenses — on te prévient avant la dérive.'**
  String get blankBudgetSubtitle;

  /// No description provided for @blankBudgetPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la première dépense'**
  String get blankBudgetPrimary;

  /// No description provided for @blankBudgetSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Estimer avec l’IA'**
  String get blankBudgetSecondary;

  /// No description provided for @budgetHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 dépense} other{{count} dépenses}}'**
  String budgetHeroMeta(int count);

  /// No description provided for @blankSharesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Planifiez ensemble.'**
  String get blankSharesTitle;

  /// No description provided for @blankSharesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Invite un proche. Il voit le voyage, tu gardes le contrôle.'**
  String get blankSharesSubtitle;

  /// No description provided for @blankSharesPrimary.
  ///
  /// In fr, this message translates to:
  /// **'Inviter un premier voyageur'**
  String get blankSharesPrimary;

  /// No description provided for @sharesHeroMeta.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 invité} other{{count} invités}}'**
  String sharesHeroMeta(int count);

  /// No description provided for @panelQuickAddItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un objet'**
  String get panelQuickAddItem;

  /// No description provided for @panelQuickAddExpense.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une dépense'**
  String get panelQuickAddExpense;

  /// No description provided for @panelQuickAddActivity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une activité'**
  String get panelQuickAddActivity;

  /// No description provided for @panelQuickAddFlight.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un vol'**
  String get panelQuickAddFlight;

  /// No description provided for @panelQuickAddStay.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un hébergement'**
  String get panelQuickAddStay;

  /// No description provided for @panelInviteCollaborator.
  ///
  /// In fr, this message translates to:
  /// **'Inviter'**
  String get panelInviteCollaborator;

  /// No description provided for @panelActionEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get panelActionEdit;

  /// No description provided for @panelActionDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get panelActionDelete;

  /// No description provided for @panelActionDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get panelActionDuplicate;

  /// No description provided for @panelOpenFullBaggage.
  ///
  /// In fr, this message translates to:
  /// **'Voir la checklist complète'**
  String get panelOpenFullBaggage;

  /// No description provided for @panelOpenFullBudget.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail complet'**
  String get panelOpenFullBudget;

  /// No description provided for @panelOpenFullActivities.
  ///
  /// In fr, this message translates to:
  /// **'Voir l’itinéraire complet'**
  String get panelOpenFullActivities;

  /// No description provided for @panelOpenFullFlights.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les vols'**
  String get panelOpenFullFlights;

  /// No description provided for @panelOpenFullAccommodations.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les hébergements'**
  String get panelOpenFullAccommodations;

  /// No description provided for @panelOpenFullShares.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les accès'**
  String get panelOpenFullShares;

  /// No description provided for @baggageAllPackedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tout est prêt — bon voyage.'**
  String get baggageAllPackedMessage;

  /// No description provided for @budgetRecentExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Récentes'**
  String get budgetRecentExpenses;

  /// No description provided for @activityValidateAction.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get activityValidateAction;

  /// No description provided for @activitySuggestedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Suggérée'**
  String get activitySuggestedBadge;

  /// No description provided for @shareCopyLink.
  ///
  /// In fr, this message translates to:
  /// **'Copier le lien d’invitation'**
  String get shareCopyLink;

  /// No description provided for @shareRevokeAccess.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer l’accès'**
  String get shareRevokeAccess;
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
