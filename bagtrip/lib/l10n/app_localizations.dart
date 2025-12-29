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
  /// **'Premium Économique'**
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

  /// No description provided for @passengersChildren.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get passengersChildren;

  /// No description provided for @passengersInfants.
  ///
  /// In fr, this message translates to:
  /// **'Bébés'**
  String get passengersInfants;

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
