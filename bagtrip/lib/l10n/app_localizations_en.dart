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
  String get disconnect => 'Disconnect';

  @override
  String get continueButton => 'Continue';

  @override
  String get retryButton => 'Retry';

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
  String get noRecentBookings => 'No recent bookings';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get loginWelcomeTitle => 'Welcome to \nBag Trip';

  @override
  String get loginWelcomeGreeting => 'Welcome to';

  @override
  String get loginWelcomeAppName => 'BagTrip';

  @override
  String get loginWelcomeSubtitle => 'Your smart travel companion';

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
  String get splashConnectionErrorTitle => 'Connection error';

  @override
  String get splashConnectionErrorMessage =>
      'Unable to reach the server. Please check your internet connection and try again.';

  @override
  String get personalizationProfileSectionTitle => 'Experience personalization';

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
  String get personalizationTravelStylePlanned => 'Fully planned';

  @override
  String get personalizationTravelStyleFlexible => 'Flexible';

  @override
  String get personalizationTravelStyleSpontaneous => 'Spontaneous';

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
  String get planifierGreeting => 'Good morning';

  @override
  String get destinationPlaceholder => 'Paris, Tokyo, New York...';

  @override
  String get recapDateChoose => 'Choose';

  @override
  String get recapDateSelectHint => 'Select';

  @override
  String get summarySectionWhereStay => 'WHERE YOU\'LL STAY';

  @override
  String get summarySectionFlight => 'FLIGHT';

  @override
  String get summarySectionYourJourney => 'YOUR JOURNEY';

  @override
  String get summarySectionEssentials => 'ESSENTIALS';

  @override
  String get summaryDayPrefix => 'D';

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
  String get activityTitle => 'Title';

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
  String get activityDeleteTitle => 'Delete activity';

  @override
  String get activityDeleteConfirm =>
      'Are you sure you want to delete this activity?';

  @override
  String get activityEndTimeBeforeStartTime =>
      'End time must be after start time';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryOther => 'Other';

  @override
  String get budgetItems => 'Budget';

  @override
  String get addExpense => 'Add expense';

  @override
  String get editExpense => 'Edit expense';

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
  String get expenseLabelRequired => 'Label is required';

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
  String get notificationsJustNow => 'Just now';

  @override
  String notificationsMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String notificationsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String notificationsShortDaysAgo(int count) {
    return '${count}d ago';
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
  String get baggageQuantityLabel => 'Qty';

  @override
  String get baggageCategoryLabel => 'Category (optional)';

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
  String get baggageEditItemTitle => 'Edit item';

  @override
  String get baggageItemName => 'Item name';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get accommodationsTitle => 'Accommodations';

  @override
  String get accommodationCheckInLabel => 'Check-in';

  @override
  String get accommodationCheckOutLabel => 'Check-out';

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
  String get sharesRevokeButton => 'Revoke';

  @override
  String get sharesEmpty => 'No shares';

  @override
  String get sharesEmptySubtitle => 'Invite people to view your trip';

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
  String postTripSuggestionDuration(int days) {
    return '$days days';
  }

  @override
  String postTripSuggestionBudget(String amount) {
    return '$amount€';
  }

  @override
  String get feedbackNoReviews => 'No reviews';

  @override
  String feedbackHighlightsPrefix(String highlights) {
    return 'Highlights: $highlights';
  }

  @override
  String feedbackLowlightsPrefix(String lowlights) {
    return 'To improve: $lowlights';
  }

  @override
  String get feedbackRecommends => 'Recommends';

  @override
  String get feedbackNotRecommends => 'Does not recommend';

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
  String get premiumPaywallTitle => 'Go Premium';

  @override
  String tripDurationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String tripShareInvitedOnDate(String date) {
    return 'Invited on $date';
  }

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
  String get bookingLabel => 'Booking';

  @override
  String get activitiesTitle => 'Activities';

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
  String nextTripCountdown(int days) {
    return 'In $days days';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get personalInfoPageTitle => 'Personal information';

  @override
  String get travelPreferencesTitle => 'Travel preferences';

  @override
  String homeGreeting(String name) {
    return 'Welcome, $name';
  }

  @override
  String homeGreetingMorning(String name) {
    return 'Good morning,\n$name';
  }

  @override
  String homeGreetingAfternoon(String name) {
    return 'Good afternoon,\n$name';
  }

  @override
  String homeGreetingEvening(String name) {
    return 'Good evening,\n$name';
  }

  @override
  String get homeWelcomeTitle => 'Ready to travel?';

  @override
  String get homeSubtitleEmpty => 'Where will you go next?';

  @override
  String get homeSubtitleOneTrip => '1 trip planned';

  @override
  String homeSubtitleTrips(int count) {
    return '$count trips planned';
  }

  @override
  String get homeCreateFirstTrip => 'Create my first trip';

  @override
  String get planTripCta => 'Plan a trip';

  @override
  String get homeCtaAiOrManual => 'AI or manual';

  @override
  String get homeCtaStartPlanning => 'Start planning';

  @override
  String get inspireMe => 'Inspire me';

  @override
  String get datesLabel => 'DATES';

  @override
  String get datesChooseDatePlaceholder => 'Choose a date';

  @override
  String tripNightsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get days => 'days';

  @override
  String get tripCreatedSuccess => 'Trip created successfully!';

  @override
  String get stepDestination => 'Where?';

  @override
  String get stepTravelers => 'Who?';

  @override
  String get stepReview => 'Review';

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
  String get emptyFlightsTitle => 'Ready to fly?';

  @override
  String get emptyFlightsSubtitle =>
      'Add your flights to track dates and times';

  @override
  String get noActivitiesThisDay => 'Nothing planned for this day yet';

  @override
  String get emptyActivitiesTitle => 'What will you discover?';

  @override
  String get emptyActivitiesSubtitle => 'Add activities to plan your trip';

  @override
  String get emptyBaggageTitle => 'What do you need to pack?';

  @override
  String get emptyBaggageSubtitle => 'Add items to your luggage list';

  @override
  String baggageProgressLabel(int packed, int total) {
    return '$packed / $total packed';
  }

  @override
  String get emptySharesTitle => 'Travel together';

  @override
  String get emptySharesSubtitle =>
      'Invite travel partners to collaborate on this trip';

  @override
  String get budgetSeeAllExpenses => 'See all expenses';

  @override
  String budgetOverBudgetBanner(String amount) {
    return 'Over budget by $amount';
  }

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
  String get travelerTypeAdults => 'Adults';

  @override
  String get travelerTypeChildren => 'Children';

  @override
  String get travelerTypeBabies => 'Babies';

  @override
  String get travelerAgeAdultsSubtitle => 'Ages 13+';

  @override
  String get travelerAgeChildrenSubtitle => 'Ages 3–12';

  @override
  String get travelerAgeBabiesSubtitle => 'Ages 0–2';

  @override
  String travelerSegmentAdult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return '$_temp0';
  }

  @override
  String travelerSegmentChild(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String travelerSegmentBaby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count babies',
      one: '1 baby',
    );
    return '$_temp0';
  }

  @override
  String planTripDurationDaysNights(int days, int nights) {
    return '$days days · $nights nights';
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
  String get destinationPopularSectionLabel => 'POPULAR RIGHT NOW';

  @override
  String get destinationOrSeparator => 'OR';

  @override
  String get destinationNoResults => 'No results found';

  @override
  String get destinationAiLoading => 'Our AI is searching for you...';

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
  String get reviewBudgetEstimationPrefix => 'estimation';

  @override
  String get reviewBudgetUnavailable => 'Budget estimation unavailable';

  @override
  String get reviewSourceVerified => 'Verified';

  @override
  String get reviewSourceEstimated => 'Estimated';

  @override
  String reviewPriceEur(String amount) {
    return '$amount EUR';
  }

  @override
  String get reviewHighlightsLabel => 'HIGHLIGHTS';

  @override
  String get reviewSectionDates => 'DATES';

  @override
  String get reviewDatesSuggested => 'Suggested dates — tap to adjust';

  @override
  String reviewEssentialReason(String reason) {
    return 'Why: $reason';
  }

  @override
  String get reviewNoActivities => 'No activities planned';

  @override
  String get reviewTabOverview => 'Overview';

  @override
  String get reviewTabFlights => 'Flights';

  @override
  String get reviewTabHotel => 'Hotel';

  @override
  String get reviewTabItinerary => 'Itinerary';

  @override
  String get reviewTabEssentials => 'Essentials';

  @override
  String get reviewTabBudget => 'Budget';

  @override
  String get reviewTimelineFlight => 'Flight';

  @override
  String get reviewTimelineActivity => 'Activity';

  @override
  String get reviewTimelineCheckIn => 'Check-in';

  @override
  String get reviewTimelineCheckOut => 'Check-out';

  @override
  String get reviewFlightOutbound => 'Outbound';

  @override
  String get reviewFlightReturn => 'Return';

  @override
  String get reviewFlightDeparture => 'Departure';

  @override
  String get reviewFlightArrival => 'Arrival';

  @override
  String get reviewHotelCheckIn => 'Check-in';

  @override
  String get reviewHotelCheckOut => 'Check-out';

  @override
  String get reviewHotelNights => 'Nights';

  @override
  String get reviewHotelPerNight => 'Per night';

  @override
  String reviewSummaryLine(int days, String city, String travelers) {
    return '$days days in $city for $travelers';
  }

  @override
  String reviewSummaryTravelers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count travelers',
      one: '1 traveler',
    );
    return '$_temp0';
  }

  @override
  String get reviewJourneyHeader => 'Your journey';

  @override
  String reviewDayTitle(int day, String date) {
    return 'Day $day · $date';
  }

  @override
  String get reviewDayFree => 'A free day';

  @override
  String reviewFlightDurationHm(int hours, String minutes) {
    return '${hours}h$minutes';
  }

  @override
  String get reviewHotelArrival => 'Check-in';

  @override
  String reviewHotelStayNights(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String get reviewBudgetHeader => 'The budget';

  @override
  String reviewBudgetPerPerson(String amount) {
    return '$amount per traveler';
  }

  @override
  String get reviewDecisionHeader => 'Your call';

  @override
  String get reviewDecisionPrimary => 'Plan this trip';

  @override
  String homeActiveTripTitle(String destination) {
    return 'Your trip to $destination';
  }

  @override
  String homeActiveTripDay(int current, int total) {
    return 'Day $current of $total';
  }

  @override
  String get homeActiveTripEyebrow => 'TRIP IN PROGRESS';

  @override
  String get homeNavPillTitle => 'Trips & home';

  @override
  String get homeNavPillSubtitle => 'Manage trips, create a new one';

  @override
  String get homeResumeActiveTripCta => 'Continue trip';

  @override
  String get homeResumeActiveTripSubtitle => 'Your trip is still active';

  @override
  String get homeSectionNowBadge => 'NOW';

  @override
  String get endTripSheetTitle => 'End trip?';

  @override
  String get endTripSheetMessage =>
      'You can finish this trip now or decide later.';

  @override
  String get endTripSheetTerminate => 'End trip';

  @override
  String get endTripSheetPostpone => 'Decide later';

  @override
  String get toastTripCompleted => 'Trip completed';

  @override
  String get qaEndTrip => 'End trip';

  @override
  String get homeTodayActivities => 'Today\'s schedule';

  @override
  String get activeHomeProgrammeTitle => 'Schedule';

  @override
  String get activeHomeNoActivitiesDay => 'No activities on this day';

  @override
  String get activeHomeContextPast => 'Past';

  @override
  String get activeHomeContextToday => 'TODAY';

  @override
  String get activeHomeContextTomorrow => 'Tomorrow';

  @override
  String activeHomeContextTripDay(int day) {
    return 'J$day';
  }

  @override
  String get activeHomeLastTripDayBanner => 'Last day of your trip';

  @override
  String get scheduleBadgeDone => 'Done';

  @override
  String get scheduleBadgeNow => 'Now';

  @override
  String get scheduleBadgeNext => 'Next';

  @override
  String get scheduleBadgeLater => 'Later';

  @override
  String get homeNoActivitiesToday => 'No activities planned today';

  @override
  String get tripCardNoDestination => 'No destination';

  @override
  String get tripCardNoTitle => 'Untitled trip';

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
  String get activeTripQuickActionNavigateSubtitle => 'Open directions in Maps';

  @override
  String get activeTripQuickActionExpenseSubtitle =>
      'Budget tracking for this trip';

  @override
  String get activeTripQuickActionPhotoTitle => 'Trip photo';

  @override
  String get activeTripQuickActionPhotoSubtitle =>
      'Capture and add to your journal';

  @override
  String get activeTripQuickActionTomorrowTitle => 'Go to tomorrow';

  @override
  String get activeTripQuickActionTomorrowSubtitle =>
      'Show tomorrow\'s schedule';

  @override
  String get activeTripQuickActionNextDayTitle => 'Next day';

  @override
  String get activeTripQuickActionNextDaySubtitle =>
      'Show the next day\'s schedule';

  @override
  String get activeTripEndTripCardTitle => 'End trip';

  @override
  String activeTripEndTripCardSubtitle(String destination) {
    return 'Mark $destination as finished';
  }

  @override
  String get activeTripWeatherUnavailable => 'Weather unavailable';

  @override
  String activeTripWeatherRainShort(int percent) {
    return '$percent% rain';
  }

  @override
  String get completionDates => 'Dates';

  @override
  String get completionFlights => 'Flights';

  @override
  String get completionAccommodation => 'Hotels';

  @override
  String get completionActivities => 'Activities';

  @override
  String get completionBaggage => 'Luggage';

  @override
  String get completionBudget => 'Budget';

  @override
  String get tripDetailQuickFlights => 'Flights';

  @override
  String get tripDetailQuickActivities => 'Activities';

  @override
  String get tripDetailQuickAddFlight => 'Add flight';

  @override
  String get tripDetailQuickAddHotel => 'Add hotel';

  @override
  String get tripDetailQuickAddActivity => 'Add activity';

  @override
  String get tripDetailQuickExpense => 'Expense';

  @override
  String get tripDetailQuickBaggage => 'Baggage';

  @override
  String get tripDetailQuickMemories => 'Memories';

  @override
  String get timelineSectionTitle => 'Itinerary';

  @override
  String get timelineMorning => 'Morning';

  @override
  String get timelineAfternoon => 'Afternoon';

  @override
  String get timelineEvening => 'Evening';

  @override
  String get timelineEmptyDayTitle => 'No activities yet';

  @override
  String get timelineEmptyDaySubtitle =>
      'Add some or ask the AI to suggest ideas';

  @override
  String get timelineValidate => 'Validate';

  @override
  String get timelineReject => 'Reject';

  @override
  String get flightStatusConfirmed => 'Confirmed';

  @override
  String get flightStatusPending => 'Pending';

  @override
  String get flightsSectionEmptyTitle => 'Where are you flying?';

  @override
  String get flightsSectionEmptySubtitle =>
      'Add your flights to start organizing your trip';

  @override
  String flightsSectionSeeAll(int count) {
    return 'See all flights ($count)';
  }

  @override
  String get flightsSectionTitle => 'Flights';

  @override
  String accommodationSectionSeeAll(int count) {
    return 'See all accommodations ($count)';
  }

  @override
  String get accommodationStatusConfirmed => 'Confirmed';

  @override
  String get accommodationStatusPending => 'Pending';

  @override
  String baggageSectionSeeAll(int count) {
    return 'See all items ($count)';
  }

  @override
  String get baggageSectionAddItem => 'Add an item';

  @override
  String get baggageSectionAddItemSubtitle => 'Create your packing list';

  @override
  String get baggageSectionAiSuggest => 'Get AI suggestions';

  @override
  String get baggageSectionAiSuggestSubtitle => 'Let AI help you pack';

  @override
  String get budgetEstimateOptionSubtitle =>
      'Let AI suggest a budget for your trip';

  @override
  String get budgetAddExpenseSubtitle => 'Track a planned or actual expense';

  @override
  String get budgetManageAll => 'Manage budget';

  @override
  String get budgetCategoryBreakdown => 'Breakdown';

  @override
  String get sharingSectionTitle => 'Sharing';

  @override
  String get sharingSectionEmptyTitle => 'Share your trip';

  @override
  String get sharingSectionEmptySubtitle =>
      'Invite friends and family to follow along';

  @override
  String get sharingSectionInvite => 'Invite someone';

  @override
  String get sharingSectionInviteSubtitle => 'Share your trip with others';

  @override
  String sharingSectionSeeAll(int count) {
    return 'See all members ($count)';
  }

  @override
  String get sharingSectionOwner => 'Owner';

  @override
  String get sharingSectionViewer => 'Viewer';

  @override
  String get sharingSectionYou => 'You';

  @override
  String timelineInMinutes(int minutes) {
    return 'In $minutes min';
  }

  @override
  String get timelineNow => 'Now';

  @override
  String get timelineInProgress => 'In progress';

  @override
  String timelineRemainingMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String get timelineNavigate => 'Navigate';

  @override
  String get timelineChooseMapApp => 'Choose map app';

  @override
  String get timelineAppleMaps => 'Apple Maps';

  @override
  String get timelineGoogleMaps => 'Google Maps';

  @override
  String get activeTripsTomorrowLastDay => 'Last day of the trip';

  @override
  String activeTripsTomorrowShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get activeTripsTomorrowCollapse => 'Show less';

  @override
  String get qaSchedule => 'Schedule';

  @override
  String get qaWeather => 'Weather';

  @override
  String get qaCheckOut => 'Check-out';

  @override
  String get qaNavigate => 'Navigate';

  @override
  String get qaExpense => 'Expense';

  @override
  String get qaPhoto => 'Photo';

  @override
  String get qaNextActivity => 'Next up';

  @override
  String get qaAiSuggestion => 'AI Idea';

  @override
  String get qaMap => 'Map';

  @override
  String get qaTodayExpenses => 'Today';

  @override
  String get qaTomorrow => 'Tomorrow';

  @override
  String get qaBudget => 'Budget';

  @override
  String get qaQuickExpenseTitle => 'Quick expense';

  @override
  String get qaQuickExpenseNote => 'Note (optional)';

  @override
  String get qaQuickExpenseAmount => 'Amount';

  @override
  String get qaQuickExpenseAmountRequired => 'Amount is required';

  @override
  String get qaQuickExpenseInvalidAmount => 'Invalid amount';

  @override
  String get qaCategoryFood => 'Food';

  @override
  String get qaCategoryTransport => 'Transport';

  @override
  String get qaCategoryActivity => 'Activity';

  @override
  String get qaCategoryOther => 'Other';

  @override
  String get postTripDetectionTitle => 'Trip completed!';

  @override
  String postTripDetectionMessage(String destination) {
    return 'Your trip to $destination has ended. Would you like to mark it as completed?';
  }

  @override
  String get postTripDetectionConfirm => 'Yes, complete';

  @override
  String get postTripDetectionRemindLater => 'Remind me later';

  @override
  String get postTripSouvenirsTitle => 'Souvenirs';

  @override
  String postTripDaysCount(int count) {
    return '$count days of adventure';
  }

  @override
  String postTripActivitiesCompleted(int completed, int total) {
    return '$completed of $total activities';
  }

  @override
  String postTripBudgetSpent(String amount) {
    return '$amount spent';
  }

  @override
  String postTripCategoriesExplored(int count) {
    return '$count categories explored';
  }

  @override
  String get postTripGiveReview => 'Share your experience';

  @override
  String get postTripPlanNext => 'Plan your next trip';

  @override
  String get feedbackAiRatingLabel => 'Rate the AI planning experience';

  @override
  String get editTripTitle => 'Edit trip name';

  @override
  String get editTripDates => 'Trip dates';

  @override
  String get editTripStartDate => 'Start date';

  @override
  String get editTripEndDate => 'End date';

  @override
  String get editTripTravelers => 'Travelers';

  @override
  String get activitiesOutOfRangeTitle => 'Activities out of range';

  @override
  String activitiesOutOfRangeMessage(int count) {
    return '$count activities fall outside the new dates';
  }

  @override
  String get cannotFinalizeTitle => 'Cannot finalize trip';

  @override
  String get cannotFinalizeMessage => 'Add a destination and dates first';

  @override
  String get finalizeMissingDestination => 'Missing destination';

  @override
  String get finalizeMissingDates => 'Missing travel dates';

  @override
  String get routeSectionLabel => 'Route';

  @override
  String get scheduleSectionLabel => 'Schedule';

  @override
  String get detailsSectionLabel => 'Details';

  @override
  String get airportsMustDiffer =>
      'Departure and arrival airports must be different';

  @override
  String get arrivalMustBeAfterDeparture => 'Arrival must be after departure';

  @override
  String get accommodationEditTitle => 'Edit Accommodation';

  @override
  String get accommodationSaveButton => 'Save';

  @override
  String get accommodationAddressLabel => 'Address';

  @override
  String get accommodationReferenceLabel => 'Booking reference';

  @override
  String get accommodationCheckOutBeforeCheckIn =>
      'Check-out must be after check-in';

  @override
  String get accommodationCheckInTimeLabel => 'Check-in time';

  @override
  String get accommodationCheckOutTimeLabel => 'Check-out time';

  @override
  String get accommodationSelectHotel => 'Select';

  @override
  String get accommodationPerNight => '/night';

  @override
  String get accommodationNoResults => 'No hotels found';

  @override
  String get baggageAllPacked => 'All packed!';

  @override
  String get baggageAllPackedSubtitle => 'You\'re ready for your trip!';

  @override
  String get baggageSwipeToDelete => 'Delete';

  @override
  String activityBatchCount(int count) {
    return '$count to validate';
  }

  @override
  String get activityValidateAll => 'Validate all';

  @override
  String get activityReviewOneByOne => 'Review one by one';

  @override
  String get activityBatchValidated => 'All activities validated!';

  @override
  String get categoryCulture => 'Culture';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryFoodDrink => 'Food & Drink';

  @override
  String get categorySport => 'Sport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryNightlife => 'Nightlife';

  @override
  String get categoryRelaxation => 'Relaxation';

  @override
  String get categoryOtherActivity => 'Other';

  @override
  String activityMovedToDay(int day) {
    return 'Activity moved to day $day';
  }

  @override
  String get timelineGetSuggestions => 'Get AI suggestions';

  @override
  String get timelineSuggestionsForDay => 'Suggestions for this day';

  @override
  String get timelineAddSuggestion => 'Add to itinerary';

  @override
  String get addActivityManually => 'Add manually';

  @override
  String get shareInviteTitle => 'Invite to trip';

  @override
  String get shareInviteEmailLabel => 'Email address';

  @override
  String get shareInviteEmailHint => 'user@example.com';

  @override
  String get shareInviteEmailRequired => 'Email is required';

  @override
  String get shareInviteEmailInvalid => 'Invalid email format';

  @override
  String get shareInviteMessageLabel => 'Message (optional)';

  @override
  String get shareInviteMessageHint => 'Add a personal note...';

  @override
  String get shareInviteSendButton => 'Send invite';

  @override
  String get shareRoleViewer => 'Viewer';

  @override
  String get shareRoleEditor => 'Editor';

  @override
  String get shareInvitePendingMessage =>
      'This person isn\'t registered yet. They\'ll get access when they sign up.';

  @override
  String get shareInviteLinkCopied => 'Invite link copied';

  @override
  String get shareErrorUserNotFound =>
      'This person must create an account first';

  @override
  String get shareErrorAlreadyShared => 'Already shared with this person';

  @override
  String get shareErrorSelfShare => 'You can\'t share a trip with yourself';

  @override
  String get shareRevokeConfirmTitle => 'Remove access';

  @override
  String shareRevokeConfirmMessage(String name) {
    return 'Remove access for $name?';
  }

  @override
  String get viewerBadgeReadOnly => 'Read only';

  @override
  String get shareInviteSuccess => 'Invitation sent';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterPriceLowest => 'Lowest price';

  @override
  String get filterPriceHighest => 'Highest price';

  @override
  String get filterAirline => 'Airline';

  @override
  String get filterNoAirlines => 'No airlines available';

  @override
  String get filterAllAirlines => 'All';

  @override
  String get filterBaggage => 'Baggage';

  @override
  String get filterDepartureTime => 'Departure time';

  @override
  String get filterBefore => 'Before';

  @override
  String get filterAfter => 'After';

  @override
  String get filterApply => 'Apply';

  @override
  String get doneButton => 'Done';

  @override
  String get contextMenuView => 'View';

  @override
  String get contextMenuShare => 'Share';

  @override
  String get contextMenuArchive => 'Archive';

  @override
  String get contextMenuEdit => 'Edit';

  @override
  String get contextMenuValidate => 'Validate';

  @override
  String get contextMenuDelete => 'Delete';

  @override
  String get contextMenuMoveToDay => 'Move to another day';

  @override
  String contextMenuDayLabel(int day) {
    return 'Day $day';
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
    return 'Cover photo of $destination';
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
  String get addTripTooltip => 'Add a trip';

  @override
  String get addActivityTooltip => 'Add an activity';

  @override
  String get addAccommodationTooltip => 'Add an accommodation';

  @override
  String get addTransportTooltip => 'Add a transport';

  @override
  String get addExpenseTooltip => 'Add an expense';

  @override
  String get addBaggageItemTooltip => 'Add an item';

  @override
  String get addFlightTooltip => 'Add a flight';

  @override
  String get sharesAddMemberTooltip => 'Invite member';

  @override
  String get myTripFallback => 'My trip';

  @override
  String get completionSegmentsSheetTitle => 'Still missing';

  @override
  String get completionScoreBudgetNote =>
      'The budget is tracked separately and isn\'t part of this score.';

  @override
  String get budgetViewerStatusOnTrack => 'On track';

  @override
  String get budgetViewerStatusTight => 'Tight';

  @override
  String get budgetViewerStatusOverBudget => 'Over budget';

  @override
  String get budgetViewerNoFiguresHint =>
      'Specific amounts are visible to the trip owner only.';

  @override
  String get shareTooltip => 'Share';

  @override
  String get backTooltip => 'Back';

  @override
  String get deleteFlightTooltip => 'Delete flight';

  @override
  String get editFlight => 'Edit flight';

  @override
  String get editFlightTooltip => 'Edit this flight';

  @override
  String get multiDestResults => 'Results by segment';

  @override
  String segmentLabel(int index) {
    return 'Segment $index';
  }

  @override
  String get deleteAccommodationTooltip => 'Delete accommodation';

  @override
  String get removeAccessTooltip => 'Remove access';

  @override
  String get inviteTooltip => 'Invite';

  @override
  String get acceptSuggestionTooltip => 'Accept suggestion';

  @override
  String get dismissSuggestionTooltip => 'Dismiss suggestion';

  @override
  String get decreaseQuantityTooltip => 'Decrease quantity';

  @override
  String get increaseQuantityTooltip => 'Increase quantity';

  @override
  String starRatingTooltip(int current, int total) {
    return '$current of $total stars';
  }

  @override
  String tabActivityWithBadge(int count) {
    return 'Activity, $count notifications';
  }

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address and we will send you a link to reset your password.';

  @override
  String get forgotPasswordSendButton => 'Send reset link';

  @override
  String get forgotPasswordSuccess =>
      'If this email exists, a reset link has been sent. Check your inbox.';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmMessage =>
      'This will permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get deleteAccountConfirmAction => 'Delete permanently';

  @override
  String get bookFlight => 'Book this flight';

  @override
  String get weatherSheetTitle => 'Weather';

  @override
  String get weatherSheetTemperature => 'Temperature';

  @override
  String get weatherSheetRainProbability => 'Rain probability';

  @override
  String get weatherSheetUnavailable => 'Weather data is unavailable';

  @override
  String get photoLaunchFailed => 'Could not open camera';

  @override
  String get mapLocationsTitle => 'Trip Locations';

  @override
  String get mapNoLocations => 'No locations added yet';

  @override
  String get mapDestination => 'Destination';

  @override
  String get mapActivities => 'Activities';

  @override
  String get mapAccommodations => 'Accommodations';

  @override
  String get originCityLabel => 'DEPARTING FROM';

  @override
  String get originCityPlaceholder => 'Your city';

  @override
  String get originCityHint => 'Where will you start your trip?';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundSubtitle =>
      'The page you are looking for doesn\'t exist or has been moved.';

  @override
  String get notFoundCta => 'Return home';

  @override
  String get subpageHeroBadgeViewer => 'Read only';

  @override
  String get subpageHeroBadgeCompleted => 'Completed';

  @override
  String get blankActivitiesTitle => 'Your itinerary is empty';

  @override
  String get blankActivitiesSubtitle =>
      'Plan what makes this trip worth remembering.';

  @override
  String get blankActivitiesPrimary => 'Add your first activity';

  @override
  String get blankActivitiesSecondary => 'Let AI plan a day';

  @override
  String get blankActivitiesNoDatesTitle => 'Before we plan…';

  @override
  String get blankActivitiesNoDatesSubtitle =>
      'Set your trip dates first so we know when we’re going.';

  @override
  String get blankActivitiesNoDatesPrimary => 'Back to overview';

  @override
  String activitiesHeroMeta(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get blankTransportsTitle => 'Let’s get you there.';

  @override
  String get blankTransportsSubtitle =>
      'Outbound, return, internal connections — we’ll track them all.';

  @override
  String get blankTransportsPrimary => 'Add your first flight';

  @override
  String transportsHeroMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flights',
      one: '1 flight',
    );
    return '$_temp0';
  }

  @override
  String get blankAccommodationsTitle => 'Where will you rest your head?';

  @override
  String get blankAccommodationsSubtitle =>
      'Hotel, Airbnb, friend’s couch — log it here for check-in reminders.';

  @override
  String get blankAccommodationsPrimary => 'Add a stay';

  @override
  String get blankAccommodationsSecondary => 'Get AI suggestions';

  @override
  String accommodationsHeroMeta(int count, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stays',
      one: '1 stay',
    );
    String _temp1 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get blankBaggageTitle => 'Packing starts with one item.';

  @override
  String get blankBaggageSubtitle =>
      'Build a checklist you can tick off before every trip.';

  @override
  String get blankBaggagePrimary => 'Add first item';

  @override
  String get blankBaggageSecondary => 'Suggest from my trip';

  @override
  String baggageHeroMeta(int packed, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      packed,
      locale: localeName,
      other: '$packed of $total packed',
      zero: 'nothing packed',
    );
    return '$_temp0';
  }

  @override
  String get blankBudgetTitle => 'What’s this trip worth to you?';

  @override
  String get blankBudgetSubtitle =>
      'Set a budget, track expenses — we’ll warn you before it slips.';

  @override
  String get blankBudgetPrimary => 'Add first expense';

  @override
  String get blankBudgetSecondary => 'Estimate with AI';

  @override
  String budgetHeroMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get blankSharesTitle => 'Plan together.';

  @override
  String get blankSharesSubtitle =>
      'Invite a partner, friend, or colleague. They’ll see the trip, you stay in control.';

  @override
  String get blankSharesPrimary => 'Invite your first guest';

  @override
  String sharesHeroMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guests',
      one: '1 guest',
    );
    return '$_temp0';
  }

  @override
  String get panelQuickAddItem => 'Add item';

  @override
  String get panelQuickAddExpense => 'Add expense';

  @override
  String get panelQuickAddActivity => 'Add activity';

  @override
  String get panelQuickAddFlight => 'Add flight';

  @override
  String get panelQuickAddStay => 'Add stay';

  @override
  String get panelInviteCollaborator => 'Invite';

  @override
  String get panelActionEdit => 'Edit';

  @override
  String get panelActionDelete => 'Delete';

  @override
  String get panelActionDuplicate => 'Duplicate';

  @override
  String get panelOpenFullBaggage => 'See full checklist';

  @override
  String get panelOpenFullBudget => 'See full breakdown';

  @override
  String get panelOpenFullActivities => 'See full itinerary';

  @override
  String get panelOpenFullFlights => 'See all flights';

  @override
  String get panelOpenFullAccommodations => 'See all stays';

  @override
  String get panelOpenFullShares => 'Manage access';

  @override
  String get baggageAllPackedMessage => 'All packed — ready to roll.';

  @override
  String get budgetRecentExpenses => 'Recent';

  @override
  String get activityValidateAction => 'Validate';

  @override
  String get activitySuggestedBadge => 'Suggested';

  @override
  String get shareCopyLink => 'Copy invite link';

  @override
  String get shareRevokeAccess => 'Revoke access';

  @override
  String get panelSkippedFlightsTitle => 'Flights are on you';

  @override
  String get panelSkippedFlightsMessage =>
      'You told BagTrip to stay out of your flights. We won\'t track times, nudge you on departure day, or count flights in your completion.';

  @override
  String get panelSkippedAccommodationsTitle => 'Stays are on you';

  @override
  String get panelSkippedAccommodationsMessage =>
      'You\'re handling accommodations yourself. BagTrip won\'t suggest check-in reminders or count them in your completion.';

  @override
  String get panelSkipFlightsCta => 'Don\'t track my flights';

  @override
  String get panelSkipAccommodationsCta => 'Don\'t track my stays';

  @override
  String get panelResumeFlightsCta => 'Let BagTrip track my flights again';

  @override
  String get panelResumeAccommodationsCta => 'Let BagTrip track my stays again';

  @override
  String get validationBoardEyebrow => 'Validation';

  @override
  String get validationBoardSubtitle =>
      'What\'s left before your trip is locked in.';

  @override
  String get validationBoardStatusSkipped => 'You\'re handling this yourself';

  @override
  String get validationBoardStatusNothing => 'Nothing to validate yet';

  @override
  String get validationBoardStatusAllDone => 'All validated';

  @override
  String validationBoardStatusRemaining(int remaining, int total) {
    return '$remaining of $total left';
  }

  @override
  String get budgetRealHeader => 'Real';

  @override
  String get budgetRealSubtitle => 'What you\'ve actually spent and validated.';

  @override
  String get budgetRealEmpty =>
      'No expense logged yet. Add one to start tracking.';

  @override
  String get budgetForecastHeader => 'Forecast';

  @override
  String get budgetForecastSubtitle =>
      'What the plan estimates you will spend.';

  @override
  String get budgetForecastEmpty =>
      'No forecast yet. Add a planned item or let the AI plan fill this in.';

  @override
  String budgetDeltaOver(String amount) {
    return 'Real exceeds forecast by $amount';
  }

  @override
  String budgetDeltaUnder(String amount) {
    return '$amount still awaiting confirmation';
  }

  @override
  String get premiumFeaturePageAiTitle => 'Plan without limits';

  @override
  String get premiumFeaturePageAiBody =>
      'Generate as many AI itineraries as you want — no monthly cap.';

  @override
  String get premiumFeaturePageViewersTitle => 'Travel together';

  @override
  String get premiumFeaturePageViewersBody =>
      'Invite up to 10 viewers per trip so everyone stays in sync.';

  @override
  String get premiumFeaturePageOfflineTitle => 'Stay informed offline';

  @override
  String get premiumFeaturePageOfflineBody =>
      'Get notified about your activities even without a connection.';

  @override
  String get premiumFeaturePagePostTripTitle => 'Memories that last';

  @override
  String get premiumFeaturePagePostTripBody =>
      'AI-curated highlights and suggestions after every trip.';

  @override
  String premiumPriceLabel(String price) {
    return '$price / month';
  }

  @override
  String get premiumCtaTry => 'Try Premium';

  @override
  String get premiumDisclaimerCancelAnytime => 'Cancel anytime';

  @override
  String get subscriptionFinalizing => 'Finalizing…';

  @override
  String get subscriptionAlmostThere => 'Almost there…';

  @override
  String get subscriptionTakingLonger =>
      'Stripe is taking a moment longer. We\'ll notify you as soon as it\'s confirmed.';

  @override
  String get subscriptionContinue => 'Continue';

  @override
  String get subscriptionPageTitle => 'My subscription';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusPremiumActive => 'Premium · Active';

  @override
  String get subscriptionStatusFree => 'Free plan';

  @override
  String get subscriptionLater => 'Later';

  @override
  String get subscriptionPaywallClose => 'Close';

  @override
  String get premiumActivated => 'Premium activated';

  @override
  String subscriptionStatusCancelsOn(String date) {
    return 'Cancels on $date';
  }

  @override
  String subscriptionRenewsOn(String date) {
    return 'Renews on $date';
  }

  @override
  String subscriptionExpiresOn(String date) {
    return 'Premium until $date';
  }

  @override
  String subscriptionCardLast4(String last4) {
    return '···· $last4';
  }

  @override
  String subscriptionCardExpires(String expiry) {
    return 'Expires $expiry';
  }

  @override
  String get subscriptionUpdatePaymentMethod => 'Update payment method';

  @override
  String get updatePaymentMethodSuccess => 'New card saved';

  @override
  String get subscriptionViewInvoices => 'View invoices';

  @override
  String get subscriptionCancelAction => 'Cancel subscription';

  @override
  String get subscriptionReactivateAction => 'Reactivate subscription';

  @override
  String get subscriptionFreeMessage =>
      'You\'re on the free plan. Upgrade to unlock unlimited AI generations and more.';

  @override
  String get subscriptionDiscoverPremium => 'Discover Premium';

  @override
  String get subscriptionEmptyHelp => 'No active subscription yet.';

  @override
  String get cancelSheetTitle => 'Cancel Premium?';

  @override
  String cancelSheetBodyDated(String date) {
    return 'You\'ll keep Premium until $date. We\'ll save your trips and preferences.';
  }

  @override
  String get cancelSheetBodyUndated =>
      'We\'ll save your trips and preferences. You can come back anytime.';

  @override
  String get cancelSheetConfirm => 'Confirm cancellation';

  @override
  String get cancelSheetKeep => 'Keep my subscription';

  @override
  String cancelSheetSuccessDated(String date) {
    return 'Cancellation scheduled. Premium until $date.';
  }

  @override
  String get cancelSheetSuccessUndated => 'Subscription cancelled.';

  @override
  String get reactivateSheetTitle => 'Reactivate Premium?';

  @override
  String get reactivateSheetBody =>
      'Your subscription will continue without interruption.';

  @override
  String get reactivateSheetConfirm => 'Reactivate';

  @override
  String get reactivateSheetSuccess => 'Subscription reactivated.';

  @override
  String get invoicesPageTitle => 'Invoices';

  @override
  String get invoicesEmpty => 'No invoices yet';

  @override
  String get invoicesEmptySubtitle => 'Your billing history will appear here.';

  @override
  String get invoicesDownloadPdf => 'Download PDF';

  @override
  String get invoicesViewOnStripe => 'View on Stripe';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusOpen => 'Open';

  @override
  String get invoiceStatusVoid => 'Void';

  @override
  String get invoiceStatusDraft => 'Draft';

  @override
  String get invoiceStatusUncollectible => 'Uncollectible';

  @override
  String get refundSheetTitle => 'Request a refund';

  @override
  String refundSheetCapturedLabel(String amount) {
    return '$amount captured';
  }

  @override
  String get refundModeFull => 'Full';

  @override
  String get refundModePartial => 'Partial';

  @override
  String get refundAmountLabel => 'Amount';

  @override
  String refundAmountHint(String max) {
    return 'Up to $max';
  }

  @override
  String get refundReasonLabel => 'Reason';

  @override
  String get refundReasonRequestedByCustomer => 'Requested by customer';

  @override
  String get refundReasonDuplicate => 'Duplicate charge';

  @override
  String get refundReasonFraudulent => 'Suspected fraud';

  @override
  String get refundConfirm => 'Request refund';

  @override
  String get refundSuccessMessage =>
      'Refund processed. Funds will arrive in 5–10 days.';

  @override
  String get refundUnavailableMessage =>
      'Only captured bookings can be refunded.';

  @override
  String get paymentSuccessConfirmed => 'Payment confirmed';

  @override
  String get paymentSuccessSubtitle => 'Your booking is on its way.';

  @override
  String get paymentRefundedTitle => 'Refunded';

  @override
  String get paymentSheetCanceled => 'Payment cancelled';

  @override
  String get paymentNetworkRequired =>
      'A connection is required to complete this payment.';

  @override
  String get errorAlreadyPremium => 'You\'re already on Premium.';

  @override
  String get errorNoActiveSubscription => 'No active subscription.';

  @override
  String get errorMissingStripeCustomer =>
      'Payment profile not set up. Contact support.';

  @override
  String get errorRefundExceedsRemaining =>
      'This refund exceeds the available amount.';

  @override
  String get errorAlreadyFullyRefunded =>
      'This payment has already been fully refunded.';

  @override
  String get errorInvalidRefundReason => 'Invalid refund reason.';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';
}
