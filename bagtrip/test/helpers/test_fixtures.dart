import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/auth_response.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/models/traveler_profile.dart';
import 'package:bagtrip/models/notification.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/models/booking_response.dart';
import 'package:bagtrip/models/manual_flight.dart';

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
  int? nbTravelers = 2,
  DateTime? startDate,
  DateTime? endDate,
}) {
  return Trip(
    id: id,
    userId: userId,
    title: title,
    status: status,
    destinationName: destinationName,
    nbTravelers: nbTravelers,
    startDate: startDate ?? DateTime(2024, 6),
    endDate: endDate ?? DateTime(2024, 6, 7),
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
  ActivityCategory category = ActivityCategory.culture,
}) {
  return Activity(
    id: id,
    tripId: tripId,
    title: title,
    date: date ?? DateTime(2024, 6),
    startTime: startTime,
    category: category,
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
}) {
  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    remaining: remaining,
    percentConsumed: percentConsumed,
    alertLevel: alertLevel,
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
}) {
  return AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    isRead: isRead,
    tripId: tripId,
  );
}

TripFeedback makeTripFeedback({
  String id = 'fb-1',
  String tripId = 'trip-1',
  String userId = 'user-1',
  int overallRating = 4,
  String? highlights = 'Great food',
  bool wouldRecommend = true,
}) {
  return TripFeedback(
    id: id,
    tripId: tripId,
    userId: userId,
    overallRating: overallRating,
    highlights: highlights,
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
