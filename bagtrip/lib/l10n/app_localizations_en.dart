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
  String get nameLabel => 'NAME';

  @override
  String get emailLabel => 'EMAIL';

  @override
  String get phoneLabel => 'PHONE';

  @override
  String get modifyButton => 'Modify';

  @override
  String get editNameTitle => 'Edit name';

  @override
  String get editPhoneTitle => 'Edit phone number';

  @override
  String get saveButton => 'Save';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully';

  @override
  String get profileUpdateError => 'Failed to update profile';

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
  String get recapTitle => 'Plan your trip';

  @override
  String get recapFinalStepLabel => 'AI PLANNING';

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
  String budgetExceeded(String amount) {
    return 'Budget exceeded by $amount €';
  }

  @override
  String budgetWarning(String percent) {
    return 'You have used $percent% of your budget';
  }

  @override
  String get tripCompletedReadOnly =>
      'This trip is completed. Data is read-only.';

  @override
  String get markAsReady => 'Mark as ready';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get addButton => 'Add';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get errorTitle => 'Error';

  @override
  String get backButton => 'Back';

  @override
  String get tabHome => 'Home';

  @override
  String get tabActivity => 'Activity';

  @override
  String get tabProfile => 'Profile';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsYesterday => 'Yesterday';

  @override
  String notificationsDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get baggageTitle => 'Luggage';

  @override
  String get baggageSuggestionsTooltip => 'AI Suggestions';

  @override
  String get baggageCategoryDocuments => 'Documents';

  @override
  String get baggageCategoryClothing => 'Clothing';

  @override
  String get baggageCategoryElectronics => 'Electronics';

  @override
  String get baggageCategoryHygiene => 'Hygiene';

  @override
  String get baggageCategoryMedication => 'Medication';

  @override
  String get baggageCategoryAccessories => 'Accessories';

  @override
  String get baggageCategoryOther => 'Other';

  @override
  String get baggageDeleteTitle => 'Delete item';

  @override
  String get baggageDeleteConfirm =>
      'Are you sure you want to delete this item?';

  @override
  String get baggageItemAdded => 'Item added';

  @override
  String get baggageItemDeleted => 'Item deleted';

  @override
  String get baggageItemAddedFromSuggestion => 'Item added from suggestion';

  @override
  String get baggageQuantityLabel => 'Qty';

  @override
  String get baggageCategoryLabel => 'Category (optional)';

  @override
  String get baggageEmptyTitle => 'No items';

  @override
  String get baggageEmptySubtitle => 'Add items to your luggage list';

  @override
  String get baggageAddItemTitle => 'Add an item';

  @override
  String baggagePackedCount(int packed, int total) {
    return '$packed of $total packed';
  }

  @override
  String get baggageSuggestionsTitle => 'Suggestions for you';

  @override
  String get baggageToPack => 'To pack';

  @override
  String get baggagePacked => 'Packed';

  @override
  String get baggageSwipeToPack => 'Swipe to pack';

  @override
  String get baggageUnpack => 'Unpack';

  @override
  String get baggageItemName => 'Item name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get accommodationsTitle => 'Accommodations';

  @override
  String get accommodationCheckInHelp => 'Check-in date';

  @override
  String get accommodationCheckOutHelp => 'Check-out date';

  @override
  String get accommodationAdded => 'Accommodation added successfully';

  @override
  String get accommodationDeleteTitle => 'Delete accommodation';

  @override
  String get accommodationDeleteConfirm =>
      'Are you sure you want to delete this accommodation?';

  @override
  String get accommodationDeleted => 'Accommodation deleted';

  @override
  String get accommodationCheckInLabel => 'Check-in';

  @override
  String get accommodationCheckOutLabel => 'Check-out';

  @override
  String get accommodationEmptyTitle => 'No accommodations';

  @override
  String get accommodationEmptySubtitle => 'Add your hotels and lodgings';

  @override
  String get accommodationAddTitle => 'Add an accommodation';

  @override
  String get tripTravelers => 'Travelers';

  @override
  String get tripDaysRemaining => 'Days remaining';

  @override
  String get tripTravelDays => 'Travel days';

  @override
  String get tripComplete => 'Complete trip';

  @override
  String get tripDeleteTitle => 'Delete trip';

  @override
  String get tripDeleteConfirm =>
      'Are you sure you want to delete this trip? This action is irreversible.';

  @override
  String get tripGiveReview => 'Give a review';

  @override
  String get tripsMyTrips => 'My trips';

  @override
  String get tripsNewTrip => 'New trip';

  @override
  String get tripStatusOngoing => 'Ongoing';

  @override
  String get tripStatusPlanned => 'Upcoming';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripsEmptyOngoing => 'No ongoing trips';

  @override
  String get tripsEmptyPlanned => 'No planned trips';

  @override
  String get tripsEmptyCompleted => 'No completed trips';

  @override
  String get sharesTitle => 'Shares';

  @override
  String get sharesInviteButton => 'Invite';

  @override
  String get sharesRevokeTitle => 'Revoke access';

  @override
  String get sharesRevokeConfirm =>
      'Are you sure you want to revoke access for this user?';

  @override
  String get sharesRevokeButton => 'Revoke';

  @override
  String get sharesEmpty => 'No shares';

  @override
  String get sharesEmptySubtitle => 'Invite people to view your trip';

  @override
  String get tripCreated => 'Trip created!';

  @override
  String get aiResultsTitle => 'AI Results';

  @override
  String get feedbackTitle => 'Reviews';

  @override
  String get feedbackGiveReview => 'Give a review';

  @override
  String get feedbackAllReviews => 'All reviews';

  @override
  String get feedbackGiveYourReview => 'Give your review';

  @override
  String get feedbackOverallRating => 'Overall rating';

  @override
  String get feedbackHighlights => 'Highlights';

  @override
  String get feedbackHighlightsHint => 'What did you like?';

  @override
  String get feedbackLowlights => 'Weak points';

  @override
  String get feedbackLowlightsHint => 'What could be improved?';

  @override
  String get feedbackWouldRecommend => 'Would you recommend this trip?';

  @override
  String get feedbackThanks => 'Thanks for your review!';

  @override
  String get feedbackSubmitButton => 'Submit my review';

  @override
  String get feedbackSent => 'Your review has been sent';

  @override
  String get feedbackRecommended => 'Recommended: ';

  @override
  String get feedbackDiscoverNextTrip => 'Discover my next trip';

  @override
  String get feedbackDiscoverText =>
      'Discover your next ideal trip based on your experiences.';

  @override
  String get postTripSuggestionTitle => 'Suggested next trip';

  @override
  String get postTripNextTrip => 'Your next trip';

  @override
  String get postTripBasedOnPreferences => 'Based on your preferences';

  @override
  String get postTripProposedActivities => 'Proposed activities';

  @override
  String get postTripCreateTrip => 'Create this trip';

  @override
  String get filterCabinBagIncluded => 'Cabin bag included';

  @override
  String get filterCheckedBagIncluded => 'Checked bag included';

  @override
  String get filterReset => 'Reset';

  @override
  String get premiumFeatureAiUnlimited => 'Unlimited AI generations';

  @override
  String get premiumFeatureViewers => 'Up to 10 viewers per trip';

  @override
  String get premiumFeatureOfflineNotifs => 'Offline notifications';

  @override
  String get premiumFeaturePostTrip => 'AI post-trip suggestions';

  @override
  String get premiumCtaButton => 'Upgrade to Premium - €9.99/mo';

  @override
  String get profileConfigurePreferences => 'Configure your preferences';

  @override
  String profileStyleLabel(String style) {
    return 'Style: $style';
  }

  @override
  String profileBudgetLabel(String budget) {
    return 'Budget: $budget';
  }

  @override
  String profileCompanionsLabel(String companions) {
    return 'Companions: $companions';
  }

  @override
  String get errorNetwork =>
      'Connection error. Check your internet connection.';

  @override
  String get errorAuth => 'Invalid credentials or session expired.';

  @override
  String get errorForbidden => 'Access denied.';

  @override
  String get errorNotFound => 'Resource not found.';

  @override
  String get errorValidation => 'Invalid request.';

  @override
  String get errorQuota => 'Limit reached. Upgrade to Premium to continue.';

  @override
  String get errorStaleContext => 'Context has been updated. Please refresh.';

  @override
  String get errorServer => 'Server error. Please try again later.';

  @override
  String get errorRateLimit => 'Too many requests. Please wait.';

  @override
  String get errorCancelled => 'Operation cancelled.';

  @override
  String get errorUnknown => 'An error occurred. Please try again.';

  @override
  String get errorSessionExpired => 'Session expired';

  @override
  String get bookingLabel => 'Booking';

  @override
  String get activitiesTitle => 'Activities';

  @override
  String get activitiesEmpty => 'No activities yet';

  @override
  String get activitiesEmptySubtitle => 'Add activities to plan your trip';

  @override
  String get activitiesSuggestionsTitle => 'AI Suggestions';

  @override
  String get activityFormNew => 'New Activity';

  @override
  String get activityFormEdit => 'Edit Activity';

  @override
  String get activityTitleRequired => 'Title is required';

  @override
  String get activityFormCreate => 'Create';

  @override
  String get activityFormUpdate => 'Update';

  @override
  String get activityFormBooked => 'Booked';

  @override
  String get feedbackYesLabel => 'Yes';

  @override
  String get feedbackNoLabel => 'No';

  @override
  String get offlineMode => 'You are offline. Showing cached data.';

  @override
  String get offlineWriteError =>
      'This action requires an internet connection.';

  @override
  String get loadingMore => 'Loading more...';

  @override
  String get noMoreItems => 'No more items';

  @override
  String get subscriptionVerifying => 'Verifying your subscription...';

  @override
  String get subscriptionWelcomePremium => 'Welcome to Premium!';

  @override
  String get subscriptionPending => 'Subscription pending';

  @override
  String get subscriptionSuccessMessage =>
      'You now have access to all premium features. Enjoy unlimited AI generations and more!';

  @override
  String get subscriptionPendingMessage =>
      'Your payment is being processed. It may take a moment to activate.';

  @override
  String get subscriptionCancelTitle => 'Payment not completed';

  @override
  String get subscriptionCancelMessage =>
      'Your subscription payment was not completed. You can try again or return to your profile.';

  @override
  String get subscriptionBackToProfile => 'Back to profile';

  @override
  String get paymentSuccessTitle => 'Payment confirmed!';

  @override
  String get paymentSuccessMessage =>
      'Your flight booking has been confirmed. You can view it in your trips.';

  @override
  String get paymentBackToTrips => 'Back to my trips';

  @override
  String get paymentCancelledTitle => 'Payment cancelled';

  @override
  String get paymentCancelledMessage =>
      'Your payment was cancelled. No charges were made.';

  @override
  String get payment3dsReturnTitle => 'Payment processing';

  @override
  String get payment3dsReturnMessage =>
      'Your payment is being processed. You will receive a confirmation shortly.';

  @override
  String get nextTripSection => 'Next trip';

  @override
  String nextTripCountdown(int days) {
    return 'In $days days';
  }

  @override
  String get nextTripNoUpcoming => 'No upcoming trip';

  @override
  String nextTripReady(int percent) {
    return '$percent% ready';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get personalInfoPageTitle => 'Personal information';

  @override
  String get travelPreferencesTitle => 'Travel preferences';

  @override
  String homeGreeting(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get homeWelcomeTitle => 'Ready to travel?';

  @override
  String get homeWelcomeSubtitle =>
      'Create your first trip in a few steps. Manual or AI-assisted — your choice.';

  @override
  String get homeCreateFirstTrip => 'Create my first trip';

  @override
  String get planTripCta => 'Plan a trip';

  @override
  String get planTripCtaSubtitle => 'Manual or AI-assisted';

  @override
  String get inspireMe => 'Inspire me';

  @override
  String get datesLabel => 'DATES';

  @override
  String get suggestedDuration => 'Suggested duration';

  @override
  String get days => 'days';

  @override
  String get reviewTitle => 'Summary';

  @override
  String get aiSuggestionsTitle => 'AI SUGGESTIONS';

  @override
  String get createTripButton => 'Create trip';

  @override
  String get tripCreatedSuccess => 'Trip created successfully!';

  @override
  String get stepDestination => 'Where?';

  @override
  String get stepDates => 'When?';

  @override
  String get stepTravelers => 'Who?';

  @override
  String get stepReview => 'Review';

  @override
  String get toValidateBadge => 'To validate';

  @override
  String get addFirstAccommodation => 'Add an accommodation';

  @override
  String get addFirstActivity => 'Add an activity';

  @override
  String get addFirstBaggage => 'Prepare your luggage';

  @override
  String get addFirstBudget => 'Track your expenses';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get transportsTitle => 'Transports';

  @override
  String get addFirstTransport => 'Add your flight';

  @override
  String get addFlight => 'Add a flight';

  @override
  String get addFlightSubtitle => 'Enter your flight number to get live info';

  @override
  String get searchFlightOption => 'Search a flight';

  @override
  String get searchFlightOptionSubtitle => 'Find and compare flights';

  @override
  String get addManuallyOption => 'Add manually';

  @override
  String get addManuallyOptionSubtitle => 'Enter flight details yourself';

  @override
  String get mainFlightsSection => 'Main flights';

  @override
  String get internalFlightsSection => 'Internal flights';

  @override
  String get flightNumberLabel => 'Flight number';

  @override
  String get flightNumberRequired => 'Flight number is required';

  @override
  String get airlineLabel => 'Airline';

  @override
  String get departureAirportLabel => 'Departure';

  @override
  String get arrivalAirportLabel => 'Arrival';

  @override
  String get departureDateLabel => 'Departure date';

  @override
  String get arrivalDateLabel => 'Arrival date';

  @override
  String get priceLabel => 'Price';

  @override
  String get notesLabel => 'Notes';

  @override
  String get mainFlightType => 'Main';

  @override
  String get internalFlightType => 'Internal';

  @override
  String get flightStatusOnTime => 'On time';

  @override
  String get flightStatusDelayed => 'Delayed';

  @override
  String get flightStatusCancelled => 'Cancelled';

  @override
  String get flightStatusLanded => 'Landed';

  @override
  String get flightStatusScheduled => 'Scheduled';

  @override
  String get editButton => 'Edit';

  @override
  String get activityToValidate => 'To verify';

  @override
  String get activityValidated => 'Verified';

  @override
  String get activityDisclaimerSubtitle =>
      'AI Suggestions — verify availability and prices';

  @override
  String get activityValidateConfirmTitle => 'Verify this activity?';

  @override
  String get activityValidateConfirmMessage =>
      'You can adjust the estimated cost if needed.';

  @override
  String get activityValidateCostLabel => 'Actual cost (optional)';

  @override
  String get activityValidateConfirm => 'Confirm';

  @override
  String get accommodationSearchHotels => 'Search a hotel';

  @override
  String get accommodationSearchHotelsSubtitle => 'Find and compare prices';

  @override
  String get accommodationAddManually => 'Add manually';

  @override
  String get accommodationAddManuallySubtitle =>
      'Airbnb, hostel, hotel, camping...';

  @override
  String get accommodationAiSuggestTitle => 'AI Recommendations';

  @override
  String get accommodationAiSuggestLoading => 'Generating suggestions...';

  @override
  String get accommodationEstimatedPrice => 'Estimated price';

  @override
  String get accommodationNights => 'night(s)';

  @override
  String get accommodationTotal => 'Total';

  @override
  String get accommodationSearchInArea => 'Search in area';

  @override
  String get accommodationTypeHotel => 'Hotel';

  @override
  String get accommodationTypeAirbnb => 'Airbnb';

  @override
  String get accommodationTypeHostel => 'Hostel';

  @override
  String get accommodationTypeCamping => 'Camping';

  @override
  String get accommodationTypeGuesthouse => 'Guesthouse';

  @override
  String get accommodationTypeResort => 'Resort';

  @override
  String get accommodationTypeOther => 'Other';

  @override
  String get accommodationPricePerNight => 'Price/night';

  @override
  String get accommodationUpdated => 'Accommodation updated';

  @override
  String get accommodationAiDisclaimer =>
      'AI suggestions — verify availability and prices';

  @override
  String get budgetConfirmed => 'Confirmed';

  @override
  String get budgetForecasted => 'Forecasted';

  @override
  String get budgetEstimateButton => 'Estimate my budget';

  @override
  String get budgetEstimateTitle => 'Budget estimation';

  @override
  String get budgetEstimateAccept => 'Accept';

  @override
  String get budgetEstimateModify => 'Modify';

  @override
  String get budgetAccommodationPerNight => 'Accommodation / night';

  @override
  String get budgetMealsPerDay => 'Meals / day / person';

  @override
  String get budgetLocalTransport => 'Local transport / day';

  @override
  String get budgetActivitiesTotal => 'Activities total';

  @override
  String budgetTotalRange(String min, String max, String currency) {
    return '$min – $max $currency';
  }

  @override
  String get statusPending => 'To validate';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusForecasted => 'Forecasted';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get emptyTransportsTitle => 'Where are you flying?';

  @override
  String get emptyTransportsSubtitle =>
      'Add your flights to start organizing your trip';

  @override
  String get emptyAccommodationsTitle => 'Where will you stay?';

  @override
  String get emptyAccommodationsSubtitle => 'Add your hotels and lodgings';

  @override
  String get emptyActivitiesTitle => 'What will you discover?';

  @override
  String get emptyActivitiesSubtitle => 'Add activities to plan your trip';

  @override
  String get emptyBaggageTitle => 'What do you need to pack?';

  @override
  String get emptyBaggageSubtitle => 'Add items to your luggage list';

  @override
  String get emptyBudgetTitle => 'Track your expenses';

  @override
  String get emptyBudgetSubtitle =>
      'Follow your expenses and plan your trip budget';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapComingSoonSubtitle => 'Your trip on a map. Coming soon.';

  @override
  String get mapComingSoonShort => 'Map coming soon';

  @override
  String get datesModeExact => 'Exact dates';

  @override
  String get datesModeMonth => 'Month';

  @override
  String get datesModeFlexible => 'Flexible';

  @override
  String get datesFlexibleWhenever => 'Whenever';

  @override
  String get datesFlexibleWeekend => 'Weekend';

  @override
  String get datesFlexibleWeek => '1 week';

  @override
  String get datesFlexibleTwoWeeks => '2 weeks';

  @override
  String get datesFlexibleThreeWeeks => '3 weeks';

  @override
  String get datesFlexibleWeekendDays => '2-3 days';

  @override
  String get datesFlexibleWeekDays => '7 days';

  @override
  String get datesFlexibleTwoWeeksDays => '14 days';

  @override
  String get datesFlexibleThreeWeeksDays => '21 days';

  @override
  String get planTripStepDates => 'When are you going?';

  @override
  String get travelersLabel => 'TRAVELERS';

  @override
  String travelerCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travelers',
      one: '1 traveler',
    );
    return '$_temp0';
  }

  @override
  String get budgetLabel => 'BUDGET';

  @override
  String get budgetPresetBackpacker => 'Backpacker';

  @override
  String get budgetPresetBackpackerDesc => '30–60 €/day';

  @override
  String get budgetPresetComfortable => 'Comfortable';

  @override
  String get budgetPresetComfortableDesc => '80–150 €/day';

  @override
  String get budgetPresetPremium => 'Premium';

  @override
  String get budgetPresetPremiumDesc => '200–400 €/day';

  @override
  String get budgetPresetNoLimit => 'No limit';

  @override
  String get budgetPresetNoLimitDesc => '400+ €/day';

  @override
  String get budgetEstimationLabel => 'ESTIMATED TOTAL';

  @override
  String get budgetSkipLabel => 'I\'ll decide later';

  @override
  String get destinationSectionLabel => 'DESTINATION';

  @override
  String get destinationOrSeparator => 'OR';

  @override
  String get destinationNoResults => 'No results found';

  @override
  String get destinationAiLoading => 'Our AI is searching for you...';

  @override
  String get destinationSelected => 'Selected destination';

  @override
  String get stepAiProposals => 'Your destinations';

  @override
  String get chooseThisDestination => 'Choose this destination';

  @override
  String get swipeToDiscover => 'Swipe to discover →';

  @override
  String get aiProposalsEmpty => 'No suggestions available';

  @override
  String get aiProposalsEmptySubtitle => 'Go back and try again';

  @override
  String get aiBadgeLabel => 'AI';

  @override
  String get stepGeneration => 'Generating...';

  @override
  String get generationTitle => 'AI GENERATION';

  @override
  String get generationStepDestinations => 'Destinations';

  @override
  String get generationStepActivities => 'Activities';

  @override
  String get generationStepAccommodations => 'Accommodations';

  @override
  String get generationStepBaggage => 'Luggage';

  @override
  String get generationStepBudget => 'Budget';

  @override
  String get generationErrorTitle => 'Generation failed';

  @override
  String get generationErrorSubtitle =>
      'Something went wrong. Please try again.';

  @override
  String get generationTimeoutTitle => 'Taking too long';

  @override
  String get generationTimeoutSubtitle =>
      'The generation is taking longer than expected. Please try again.';

  @override
  String generationProgressLabel(int percent) {
    return '$percent%';
  }

  @override
  String get reviewCreateTrip => 'Create my trip';

  @override
  String get reviewSeeOtherDestinations => 'See other destinations';

  @override
  String get reviewCreatingTrip => 'Creating your trip...';

  @override
  String get reviewSectionBudget => 'BUDGET BREAKDOWN';

  @override
  String get reviewBudgetFlights => 'Flights';

  @override
  String get reviewBudgetAccommodation => 'Accommodation';

  @override
  String get reviewBudgetMeals => 'Meals';

  @override
  String get reviewBudgetTransport => 'Transport';

  @override
  String get reviewBudgetActivities => 'Activities';

  @override
  String get reviewBudgetOther => 'Other';

  @override
  String get reviewBudgetTotal => 'Total';

  @override
  String get reviewSourceVerified => 'Verified';

  @override
  String get reviewSourceEstimated => 'Estimated';

  @override
  String reviewDayLabel(int day) {
    return 'Day $day';
  }

  @override
  String reviewPriceEur(String amount) {
    return '$amount EUR';
  }

  @override
  String get reviewHighlightsLabel => 'HIGHLIGHTS';

  @override
  String reviewEssentialReason(String reason) {
    return 'Why: $reason';
  }

  @override
  String get reviewNoActivities => 'No activities planned';

  @override
  String homeActiveTripTitle(String destination) {
    return 'Your trip to $destination';
  }

  @override
  String homeActiveTripDay(int current, int total) {
    return 'Day $current of $total';
  }

  @override
  String get homeTodayActivities => 'Today\'s schedule';

  @override
  String get homeNoActivitiesToday => 'No activities planned today';

  @override
  String homeTripCompletion(int percent) {
    return '$percent% ready';
  }

  @override
  String get onboardingInspirationTitle => 'Get inspired';

  @override
  String get onboardingInspirationSubtitle => 'Popular destinations';

  @override
  String get tripManagerCompletedSection => 'Past adventures';

  @override
  String get tripCardNoDestination => 'No destination';

  @override
  String get tripCardNoTitle => 'Untitled trip';

  @override
  String get activeTripsViewTrip => 'View trip';

  @override
  String get activeTripsNextUp => 'Next up';

  @override
  String get activeTripsAllDay => 'All day';

  @override
  String get activeTripsTomorrow => 'Tomorrow';

  @override
  String activeTripsTomorrowCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get activeTripsQuickActions => 'Quick actions';

  @override
  String get activeTripsActivities => 'Activities';

  @override
  String get activeTripsBudget => 'Budget';

  @override
  String get activeTripsBaggage => 'Baggage';

  @override
  String get activeTripsShare => 'Share';
}
