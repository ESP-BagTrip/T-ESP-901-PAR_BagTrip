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
  String get passengersAdultsDesc => '12+ years';

  @override
  String get passengersChildren => 'Children';

  @override
  String get passengersChildrenDesc => '2-11 years';

  @override
  String get passengersInfants => 'Infants';

  @override
  String get passengersInfantsDesc => 'Under 2 years';

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
  String get whereNextLabel => 'What\'s your next trip?';

  @override
  String get findYourFlightTitle => 'Find your flight';

  @override
  String get departLabel => 'Depart';

  @override
  String get cabinClassLabel => 'Cabin class';

  @override
  String get tripDetailsLabel => 'Trip details';

  @override
  String get flightCardTitle => 'Flight';

  @override
  String get hotelCardTitle => 'Hotel';

  @override
  String get flightAndHotelCardTitle => 'Flight + Hotel';

  @override
  String get otherCardTitle => 'Others';

  @override
  String get handleBudget => 'Manage your budget';

  @override
  String get trackExpensesAndPlan =>
      'Track your expenses and plan your trip according to your budget';

  @override
  String get addExpense => 'Add expense';

  @override
  String get myProfile => 'My profile';

  @override
  String get managePersonalInfo =>
      'Manage your personal information and preferences';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get viewDestinations => 'View destinations';

  @override
  String get exploreDestinations =>
      'Explore available destinations on an interactive map';

  @override
  String get startButton => 'Start';

  @override
  String get newTrip => 'New trip';

  @override
  String get createYourTrip => 'Create your trip';

  @override
  String get nameTripToStart => 'Name your trip to start planning';

  @override
  String get tripNameLabel => 'Trip name';

  @override
  String get tripNameHint => 'Ex: Vacation in Paris';

  @override
  String get continueButton => 'Continue';

  @override
  String get aiPlanning => 'AI Planning';

  @override
  String get retryButton => 'Retry';

  @override
  String get searchingInProgress => 'Searching...';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String planningTitle(String title) {
    return 'Planning $title';
  }

  @override
  String get personalInfoTitle => 'Personal Information';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get phoneLabel => 'PHONE';

  @override
  String get addressLabel => 'ADDRESS';

  @override
  String get modifyButton => 'Modify';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get languageLabel => 'LANGUAGE';

  @override
  String get themeLabel => 'THEME';

  @override
  String get chooseThemeHint => 'Choose your preferred theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String profileFooterText(String version, int year) {
    return 'Version $version · © $year Vol Airlines';
  }

  @override
  String memberSinceText(String date) {
    return 'Member since $date';
  }

  @override
  String get recentBookingsTitle => 'Recent Bookings';

  @override
  String get viewAllButton => 'View All';

  @override
  String get noRecentBookings => 'No recent bookings';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get profileLoadFailureMessage => 'Unable to load profile.';

  @override
  String get loginWelcomeTitle => 'Welcome to Bag Trip';

  @override
  String get loginWelcomeSubtitle => 'Login or Sign up to access your account';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get loginOrContinueWithEmail => 'OR CONTINUE WITH EMAIL';

  @override
  String get loginEmailPlaceholder => 'Email Address';

  @override
  String get loginPasswordPlaceholder => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get loginLegalBySigningIn =>
      'By signing in with an account, you agree to Bag Trip\'s ';

  @override
  String get loginTermsOfService => 'Terms of Service';

  @override
  String get loginPrivacyPolicy => 'Privacy Policy';

  @override
  String get loginLegalAnd => ' and ';

  @override
  String get loginContinueWithGoogle => 'Google';

  @override
  String get loginContinueWithApple => 'Apple';

  @override
  String get loginFullNameLabel => 'Full name (optional)';

  @override
  String get loginFullNameHint => 'John Doe';

  @override
  String get loginToggleNoAccount => 'No account? Sign up';

  @override
  String get loginToggleHasAccount => 'Already have an account? Login';

  @override
  String get loginErrorEmailRequired => 'Please enter your email address';

  @override
  String get loginErrorEmailInvalid => 'Invalid email address';

  @override
  String get loginErrorPasswordRequired => 'Please enter your password';

  @override
  String get loginErrorPasswordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get loginRegisterButton => 'Sign Up';

  @override
  String get onboardingTitle => 'Welcome!';

  @override
  String get onboardingSubtitle =>
      'Let\'s personalize your travel experience in a few simple steps.';

  @override
  String get onboardingFeature1Title => 'Simplified planning';

  @override
  String get onboardingFeature1Desc =>
      'Create your trip in a few steps. No more juggling a thousand tabs.';

  @override
  String get onboardingFeature2Title => 'Custom trip';

  @override
  String get onboardingFeature2Desc =>
      'Each trip adapts to your desires, your budget, and your pace.';

  @override
  String get onboardingFeature3Title => 'AI at your service';

  @override
  String get onboardingFeature3Desc =>
      'No destination in mind? Our AI guides you to the perfect trip.';

  @override
  String get onboardingCtaButton => 'Start';

  @override
  String get onboardingSkip => 'Skip introduction';

  @override
  String get splashLoading => 'Loading...';

  @override
  String get personalizationPromptTitle => 'Personalize your experience';

  @override
  String get personalizationPromptSubtitle =>
      'A few questions to get to know you better and offer tailor-made trips.';

  @override
  String get personalizationOptionTravelTypes => 'Your preferred travel types';

  @override
  String get personalizationOptionBudget => 'Your usual budget';

  @override
  String get personalizationOptionCompanions => 'Who you travel with';

  @override
  String get personalizationCompleteProfile => 'Complete my profile >';

  @override
  String get personalizationSkipStep => 'Skip this step';

  @override
  String get personalizationProfileSectionTitle => 'Experience personalization';

  @override
  String get personalizationPageTitle => 'My travel profile';

  @override
  String get personalizationDone => 'Done';

  @override
  String get personalizationStepTitleTravelTypes =>
      'Your preferred travel types';

  @override
  String get personalizationStepSubtitleTravelTypes =>
      'Select one or more types';

  @override
  String get personalizationTravelTypeBeach => 'Beach & Relaxation';

  @override
  String get personalizationTravelTypeAdventure => 'Adventure & Nature';

  @override
  String get personalizationTravelTypeCity => 'City & Culture';

  @override
  String get personalizationTravelTypeGastronomy => 'Gastronomy';

  @override
  String get personalizationTravelTypeWellness => 'Wellness & Spa';

  @override
  String get personalizationTravelTypeNightlife => 'Party & Nightlife';

  @override
  String get personalizationStepTitleTravelStyle => 'Your travel style';

  @override
  String get personalizationStepSubtitleTravelStyle =>
      'How do you like to organize your trips?';

  @override
  String get personalizationTravelStylePlanned => 'Fully planned';

  @override
  String get personalizationTravelStyleFlexible => 'Flexible';

  @override
  String get personalizationTravelStyleSpontaneous => 'Spontaneous';

  @override
  String get personalizationStepTitleBudget => 'Your usual budget';

  @override
  String get personalizationStepSubtitleBudget =>
      'What is your preferred spending level?';

  @override
  String get personalizationBudgetEconomical => 'Economical';

  @override
  String get personalizationBudgetEconomicalDesc => 'Hostels, local transport';

  @override
  String get personalizationBudgetModerate => 'Moderate';

  @override
  String get personalizationBudgetModerateDesc => '3★ Hotels, comfort';

  @override
  String get personalizationBudgetLuxury => 'Luxury';

  @override
  String get personalizationBudgetLuxuryDesc => '5★ Hotels, VIP experiences';

  @override
  String get personalizationStepTitleCompanions => 'Who do you travel with?';

  @override
  String get personalizationStepSubtitleCompanions =>
      'Generally, you travel...';

  @override
  String get personalizationCompanionSolo => 'Solo';

  @override
  String get personalizationCompanionCouple => 'As a couple';

  @override
  String get personalizationCompanionFamily => 'With family';

  @override
  String get personalizationCompanionFriends => 'With friends';

  @override
  String get personalizationContinue => 'Continue';

  @override
  String get personalizationFinish => 'Finish';

  @override
  String get personalizationSkip => 'Skip';

  @override
  String get personalizationWelcomeTitle => 'Welcome';

  @override
  String get personalizationWelcomeSubtitle =>
      'Let\'s personalize your travel experience';

  @override
  String get personalizationWelcomeCta => 'Start';

  @override
  String get personalizationStepTitleHowYouTravel => 'How do you travel?';

  @override
  String get personalizationStepTitleInterests => 'Your interests';

  @override
  String get personalizationStepSubtitleInterests => 'Select one or more';

  @override
  String get personalizationStepTitleBudgetQuestion => 'What is your budget?';

  @override
  String get personalizationStepTitleFrequency => 'How often do you travel?';

  @override
  String get personalizationStepSubtitleFrequency => 'Per year';

  @override
  String get personalizationBudgetComfort => 'Comfort';

  @override
  String get personalizationBudgetComfortDesc => '4★ Hotels, good balance';

  @override
  String get personalizationFrequency1_2 => '1–2 times';

  @override
  String get personalizationFrequency3_5 => '3–5 times';

  @override
  String get personalizationFrequency6Plus => '6+ times';

  @override
  String get personalizationInterestPhotography => 'Photography';

  @override
  String get personalizationInterestShopping => 'Shopping';

  @override
  String get planifierTab => 'Plan';

  @override
  String get planifierSectionCreateTrip => 'Create a trip';

  @override
  String get planifierManualTitle => 'Plan manually';

  @override
  String get planifierManualDesc =>
      'Create your trip step by step with all the details';

  @override
  String get planifierAITitle => 'AI Assistant';

  @override
  String get planifierAIDesc => 'Let AI help you create a personalized trip';

  @override
  String get planifierSectionMyTrips => 'My trips';

  @override
  String get planifierInProgressTitle => 'In progress';

  @override
  String planifierInProgressCount(int count) {
    return '$count trip(s) pending';
  }

  @override
  String get planifierCompletedTitle => 'Completed trips';

  @override
  String get planifierCompletedDesc => 'View your past trips and budgets';

  @override
  String get planifierGreeting => 'Good morning';

  @override
  String get planifierMainTitle => 'Plan your\nnext journey';

  @override
  String get planifierSubtitle => 'Create and manage your trips';

  @override
  String get planifierManualDescriptionCard =>
      'Build your itinerary step by step with full control.';

  @override
  String get planifierAIDescriptionCard =>
      'Let AI craft a personalized trip for you.';

  @override
  String get planifierNewBadge => 'NEW';

  @override
  String get planifierPlanningTitle => 'Planning';

  @override
  String get planifierPlanningDescription => 'Trips being prepared';

  @override
  String planifierInProgressSuffix(int count) {
    return '$count in progress';
  }

  @override
  String get planifierCompletedShort => 'Completed';

  @override
  String get planifierCompletedDescriptionCard => 'Past trips & budgets';

  @override
  String planifierCompletedSuffix(int count) {
    return '$count completed';
  }

  @override
  String get planifierSectionExploreDestinations => 'Explore destinations';

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
  String get yourDestinationTitle => 'Your destination';

  @override
  String get destinationPlaceholder => 'Paris, Tokyo, New York...';

  @override
  String get numberOfTravelersLabel => 'Number of travelers';

  @override
  String get nextButton => 'Next';

  @override
  String get travelerCount5Plus => '5+';

  @override
  String get transportTitle => 'Transport';

  @override
  String get transportOptionFlightTitle => 'Yes, search for a flight';

  @override
  String get transportOptionFlightSubtitle => 'Search via Amadeus';

  @override
  String get transportOptionOtherTitle => 'No, other transport';

  @override
  String get transportOptionOtherSubtitle => 'Car, train, bus...';

  @override
  String get transportOptionSkipTitle => 'No, skip this step';

  @override
  String get transportOptionSkipSubtitle => 'No transport to add';

  @override
  String get otherTransportTitle => 'Other transport';

  @override
  String get transportTypeLabel => 'Type of transport';

  @override
  String get transportTypeCar => 'Car';

  @override
  String get transportTypeTrain => 'Train';

  @override
  String get transportTypeBus => 'Bus';

  @override
  String get transportTypeFlightBooked => 'Flight (already booked)';

  @override
  String get transportDetailsLabel => 'Details (optional)';

  @override
  String get transportDetailsPlaceholder =>
      'Ex: Hertz rental, TGV Paris-Lyon...';

  @override
  String get transportBudgetLabel => 'Transport budget (€)';

  @override
  String get transportBudgetPlaceholder => 'Ex: 150';

  @override
  String get transportBudgetHint =>
      'This amount will be added to your trip budget';

  @override
  String get skipThisStepLabel => 'Skip this step';

  @override
  String get recapTitle => 'Summary';

  @override
  String get recapFinalStepLabel => 'FINAL STEP';

  @override
  String get recapDateChoose => 'Choose';

  @override
  String get recapDateSelectHint => 'Select';

  @override
  String get recapTravelTypesLabel => 'TRAVEL TYPES';

  @override
  String get recapStyleLabel => 'STYLE';

  @override
  String get recapBudgetLabel => 'BUDGET';

  @override
  String get recapCompanionsLabel => 'COMPANIONS';

  @override
  String get recapLaunchSearchButton => 'Launch AI search';

  @override
  String get summaryTitle => 'Your personalized trip';

  @override
  String get summarySubtitle => '+ Generated by AI';

  @override
  String get summaryUpcomingJourney => '◆ UPCOMING JOURNEY';

  @override
  String get summaryDays => 'days';

  @override
  String get summaryBudget => 'budget';

  @override
  String get summarySolo => 'Solo';

  @override
  String get summarySectionCurated => 'CURATED FOR YOU';

  @override
  String get summaryTripHighlights => 'Trip highlights';

  @override
  String get summarySectionWhereStay => 'WHERE YOU\'LL STAY';

  @override
  String get summaryAccommodation => 'Accommodation';

  @override
  String get summarySectionFlight => 'FLIGHT';

  @override
  String get summaryFlight => 'Flight';

  @override
  String get summaryFlightRouteMock => 'Paris CDG → Paris Orly';

  @override
  String get summaryFlightDetailsMock => 'Round trip · Economy';

  @override
  String get summarySectionYourJourney => 'YOUR JOURNEY';

  @override
  String get summaryDayByDay => 'Day by day';

  @override
  String get summarySectionEssentials => 'ESSENTIALS';

  @override
  String get summaryWhatToBring => 'What to bring';

  @override
  String get summaryBestPick => 'Best pick';

  @override
  String get summaryDayPrefix => 'D';

  @override
  String get summaryDay1Date => 'MONDAY · JUNE 9';

  @override
  String get summaryDay2Date => 'TUESDAY · JUNE 10';

  @override
  String get summaryDay3Date => 'WEDNESDAY · JUNE 11';

  @override
  String get summaryDay4Date => 'THURSDAY · JUNE 12';

  @override
  String get summaryDay5Date => 'FRIDAY · JUNE 13';

  @override
  String get summaryDay1Description =>
      'Check in to Le Marais, stroll the historic streets, evening aperitif at Place des Vosges.';

  @override
  String get summaryDay2Description =>
      'Louvre in the morning, Notre-Dame area, Seine banks in the afternoon.';

  @override
  String get summaryDay3Description =>
      'Cooking class, market visit, dinner in a typical bistro.';

  @override
  String get summaryDay4Description =>
      'Palace of Versailles, the Hall of Mirrors and the gardens in full bloom.';

  @override
  String get summaryDay5Description =>
      'Morning at Sacré-Cœur, last café crème, afternoon flight home.';

  @override
  String get summaryCategoryTravelDay => 'Travel day';

  @override
  String get summaryCategoryCulture => 'Culture';

  @override
  String get summaryCategoryCuisine => 'Cuisine';

  @override
  String get summaryCategoryDayTrip => 'Day trip';

  @override
  String get summaryCategoryDeparture => 'Departure';

  @override
  String get summarySaveTrip => 'Save this trip';

  @override
  String get summaryRegenerate => 'Regenerate';

  @override
  String get summaryTripSaved => 'Trip saved';

  @override
  String summaryDaysCount(int count) {
    return '$count days';
  }

  @override
  String summaryBudgetAmount(String amount) {
    return '$amount budget';
  }

  @override
  String get activities => 'Activities';

  @override
  String get addActivity => 'Add Activity';

  @override
  String get editActivity => 'Edit Activity';

  @override
  String get noActivities => 'No activities yet';

  @override
  String get activityTitle => 'Title';

  @override
  String get activityDate => 'Date';

  @override
  String get activityDescription => 'Description';

  @override
  String get activityStartTime => 'Start time';

  @override
  String get activityEndTime => 'End time';

  @override
  String get activityLocation => 'Location';

  @override
  String get activityCategory => 'Category';

  @override
  String get activityEstimatedCost => 'Estimated cost';

  @override
  String get activityBooked => 'Booked';

  @override
  String get categoryVisit => 'Visit';

  @override
  String get categoryRestaurant => 'Restaurant';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categoryOther => 'Other';

  @override
  String get budgetItems => 'Budget';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get noExpenses => 'No expenses yet';

  @override
  String get expenseLabel => 'Label';

  @override
  String get expenseAmount => 'Amount';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensePlanned => 'Planned';

  @override
  String get expenseReal => 'Real';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get budgetSpent => 'Spent';

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String get categoryFlight => 'Flight';

  @override
  String get categoryAccommodation => 'Accommodation';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryActivity => 'Activity';

  @override
  String get markAsReady => 'Mark as ready';

  @override
  String get tripCompletedReadOnly =>
      'This trip is completed. No modifications allowed.';

  @override
  String budgetWarning(String pct) {
    return '$pct% of your budget has been used';
  }

  @override
  String budgetExceeded(String amount) {
    return 'Budget exceeded by $amount \u20ac';
  }
}
