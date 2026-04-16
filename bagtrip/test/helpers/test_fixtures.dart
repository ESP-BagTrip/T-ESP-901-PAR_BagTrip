import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/budget_estimation.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/suggested_baggage_item.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/models/traveler_profile.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/payment_authorize_response.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/models/flight_info.dart';

User makeUser({
  String id = 'user-1',
  String email = 'test@example.com',
  String? fullName = 'Test User',
  String? phone,
  String plan = 'FREE',
  bool isProfileCompleted = false,
  DateTime? createdAt,
  int? aiGenerationsRemaining,
}) {
  return User(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    plan: plan,
    isProfileCompleted: isProfileCompleted,
    createdAt: createdAt ?? DateTime(2024),
    aiGenerationsRemaining: aiGenerationsRemaining,
  );
}

AuthResponse makeAuthResponse({
  String accessToken = 'test-access-token',
  String refreshToken = 'test-refresh-token',
  int expiresIn = 3600,
  User? user,
}) {
  return AuthResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: expiresIn,
    user: user ?? makeUser(),
  );
}

Trip makeTrip({
  String id = 'trip-1',
  String userId = 'user-1',
  String? title = 'Paris Trip',
  TripStatus status = TripStatus.draft,
  String? destinationName = 'Paris',
  String? destinationTimezone,
  int? nbTravelers = 2,
  DateTime? startDate,
  DateTime? endDate,
  double? budgetTotal,
}) {
  return Trip(
    id: id,
    userId: userId,
    title: title,
    status: status,
    destinationName: destinationName,
    destinationTimezone: destinationTimezone,
    nbTravelers: nbTravelers,
    startDate: startDate ?? DateTime(2024, 6),
    endDate: endDate ?? DateTime(2024, 6, 7),
    budgetTotal: budgetTotal,
  );
}

TripGrouped makeTripGrouped({
  List<Trip>? ongoing,
  List<Trip>? planned,
  List<Trip>? completed,
}) {
  return TripGrouped(
    ongoing: ongoing ?? [],
    planned: planned ?? [makeTrip(status: TripStatus.planned)],
    completed: completed ?? [],
  );
}

TripHome makeTripHome({Trip? trip, TripHomeStats? stats}) {
  return TripHome(
    trip: trip ?? makeTrip(),
    stats: stats ?? const TripHomeStats(baggageCount: 5, totalExpenses: 250.0),
    features: const [
      TripFeatureTile(
        id: 'activities',
        label: 'Activities',
        icon: 'activity',
        route: '/activities',
        enabled: true,
      ),
    ],
  );
}

Activity makeActivity({
  String id = 'act-1',
  String tripId = 'trip-1',
  String title = 'Visit Eiffel Tower',
  DateTime? date,
  String? startTime = '09:00',
  String? endTime,
  ActivityCategory category = ActivityCategory.culture,
  ValidationStatus validationStatus = ValidationStatus.manual,
  bool isBooked = false,
  bool isDone = false,
}) {
  return Activity(
    id: id,
    tripId: tripId,
    title: title,
    date: date ?? DateTime(2024, 6),
    startTime: startTime,
    endTime: endTime,
    category: category,
    validationStatus: validationStatus,
    isBooked: isBooked,
    isDone: isDone,
  );
}

BudgetItem makeBudgetItem({
  String id = 'budget-1',
  String tripId = 'trip-1',
  String label = 'Hotel',
  double amount = 120.0,
  BudgetCategory category = BudgetCategory.accommodation,
}) {
  return BudgetItem(
    id: id,
    tripId: tripId,
    label: label,
    amount: amount,
    category: category,
  );
}

BudgetSummary makeBudgetSummary({
  double totalBudget = 1000,
  double totalSpent = 400,
  double remaining = 600,
  double? percentConsumed = 40.0,
  String? alertLevel,
  String? alertMessage,
  Map<String, double> byCategory = const {},
  double confirmedTotal = 300,
  double forecastedTotal = 100,
}) {
  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    remaining: remaining,
    percentConsumed: percentConsumed,
    alertLevel: alertLevel,
    alertMessage: alertMessage,
    byCategory: byCategory,
    confirmedTotal: confirmedTotal,
    forecastedTotal: forecastedTotal,
  );
}

Accommodation makeAccommodation({
  String id = 'acc-1',
  String tripId = 'trip-1',
  String name = 'Hotel Paris',
  String? address,
  DateTime? checkIn,
  DateTime? checkOut,
  double? pricePerNight,
  String? currency,
  String? bookingReference,
  String? notes,
}) {
  return Accommodation(
    id: id,
    tripId: tripId,
    name: name,
    address: address,
    checkIn: checkIn,
    checkOut: checkOut,
    pricePerNight: pricePerNight,
    currency: currency,
    bookingReference: bookingReference,
    notes: notes,
  );
}

BaggageItem makeBaggageItem({
  String id = 'bag-1',
  String tripId = 'trip-1',
  String name = 'Passport',
  bool isPacked = false,
  String? category,
  int? quantity,
}) {
  return BaggageItem(
    id: id,
    tripId: tripId,
    name: name,
    isPacked: isPacked,
    category: category,
    quantity: quantity,
  );
}

Traveler makeTraveler({
  String id = 'trav-1',
  String tripId = 'trip-1',
  String firstName = 'John',
  String lastName = 'Doe',
  String travelerType = 'ADULT',
}) {
  return Traveler(
    id: id,
    tripId: tripId,
    firstName: firstName,
    lastName: lastName,
    travelerType: travelerType,
  );
}

TravelerProfile makeTravelerProfile({
  String id = 'profile-1',
  List<String> travelTypes = const ['beach', 'culture'],
  String? travelStyle = 'comfort',
  String? budget = 'medium',
  String? companions = 'couple',
  bool isCompleted = true,
}) {
  return TravelerProfile(
    id: id,
    travelTypes: travelTypes,
    travelStyle: travelStyle,
    budget: budget,
    companions: companions,
    isCompleted: isCompleted,
  );
}

AppNotification makeAppNotification({
  String id = 'notif-1',
  String type = 'trip_update',
  String title = 'Trip Updated',
  String body = 'Your trip has been updated',
  bool isRead = false,
  String? tripId = 'trip-1',
  Map<String, dynamic>? data,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead,
    tripId: tripId,
    data: data,
    createdAt: createdAt,
  );
}

TripFeedback makeTripFeedback({
  String id = 'fb-1',
  String tripId = 'trip-1',
  String userId = 'user-1',
  int overallRating = 4,
  String? highlights = 'Great food',
  String? lowlights,
  bool wouldRecommend = true,
}) {
  return TripFeedback(
    id: id,
    tripId: tripId,
    userId: userId,
    overallRating: overallRating,
    highlights: highlights,
    lowlights: lowlights,
    wouldRecommend: wouldRecommend,
  );
}

TripShare makeTripShare({
  String id = 'share-1',
  String tripId = 'trip-1',
  String userId = 'user-2',
  String role = 'VIEWER',
  String userEmail = 'viewer@example.com',
  String? userFullName = 'Viewer User',
}) {
  return TripShare(
    id: id,
    tripId: tripId,
    userId: userId,
    role: role,
    userEmail: userEmail,
    userFullName: userFullName,
  );
}

BookingResponse makeBookingResponse({
  String id = 'book-1',
  String amadeusOrderId = 'AMZ-123',
  String status = 'confirmed',
  double priceTotal = 450.0,
  String currency = 'EUR',
  DateTime? createdAt,
}) {
  return BookingResponse(
    id: id,
    amadeusOrderId: amadeusOrderId,
    status: status,
    priceTotal: priceTotal,
    currency: currency,
    createdAt: createdAt ?? DateTime(2024, 5),
  );
}

PaymentAuthorizeResponse makePaymentAuthorizeResponse({
  String stripePaymentIntentId = 'pi_123',
  String clientSecret = 'secret_123',
  String status = 'requires_capture',
}) {
  return PaymentAuthorizeResponse(
    stripePaymentIntentId: stripePaymentIntentId,
    clientSecret: clientSecret,
    status: status,
  );
}

ManualFlight makeManualFlight({
  String id = 'flight-1',
  String tripId = 'trip-1',
  String flightNumber = 'AF123',
  String? airline = 'Air France',
  String? departureAirport = 'CDG',
  String? arrivalAirport = 'JFK',
  DateTime? departureDate,
  DateTime? arrivalDate,
}) {
  return ManualFlight(
    id: id,
    tripId: tripId,
    flightNumber: flightNumber,
    airline: airline,
    departureAirport: departureAirport,
    arrivalAirport: arrivalAirport,
    departureDate: departureDate ?? DateTime(2024, 6),
    arrivalDate: arrivalDate ?? DateTime(2024, 6),
  );
}

BudgetEstimation makeBudgetEstimation({
  double? accommodationPerNight = 120.0,
  double? mealsPerDayPerPerson = 40.0,
  double? localTransportPerDay = 15.0,
  double? activitiesTotal = 200.0,
  double? totalMin = 800.0,
  double? totalMax = 1200.0,
  String currency = 'EUR',
  String? breakdownNotes,
}) {
  return BudgetEstimation(
    accommodationPerNight: accommodationPerNight,
    mealsPerDayPerPerson: mealsPerDayPerPerson,
    localTransportPerDay: localTransportPerDay,
    activitiesTotal: activitiesTotal,
    totalMin: totalMin,
    totalMax: totalMax,
    currency: currency,
    breakdownNotes: breakdownNotes,
  );
}

SuggestedBaggageItem makeSuggestedBaggageItem({
  String name = 'Sunscreen',
  int quantity = 1,
  String category = 'Toiletries',
  String? reason = 'Essential for sunny destination',
}) {
  return SuggestedBaggageItem(
    name: name,
    quantity: quantity,
    category: category,
    reason: reason,
  );
}

FlightInfo makeFlightInfo({
  String? flightIata = 'AF123',
  String? airlineIata = 'AF',
  String? airlineName = 'Air France',
  String? status = 'active',
  String? departureIata = 'CDG',
  String? departureTerminal = '2E',
  String? departureGate = 'K45',
  String? departureTime = '2024-06-01T08:00:00',
  String? arrivalIata = 'JFK',
  String? arrivalTerminal = '1',
  String? arrivalGate = 'B22',
  String? arrivalTime = '2024-06-01T11:00:00',
}) {
  return FlightInfo(
    flightIata: flightIata,
    airlineIata: airlineIata,
    airlineName: airlineName,
    status: status,
    departureIata: departureIata,
    departureTerminal: departureTerminal,
    departureGate: departureGate,
    departureTime: departureTime,
    arrivalIata: arrivalIata,
    arrivalTerminal: arrivalTerminal,
    arrivalGate: arrivalGate,
    arrivalTime: arrivalTime,
  );
}

PaginatedResponse<T> makePaginatedResponse<T>({
  required List<T> items,
  int page = 1,
  int total = 1,
  int totalPages = 1,
}) {
  return PaginatedResponse<T>(
    items: items,
    total: total,
    page: page,
    totalPages: totalPages,
  );
}
