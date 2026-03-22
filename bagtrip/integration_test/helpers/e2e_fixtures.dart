import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/budget_item.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_di_setup.dart';

// ─── Model factories ────────────────────────────────────────────────────────

User makeUser({
  String id = 'user-1',
  String email = 'test@example.com',
  String? fullName = 'Test User',
  String plan = 'FREE',
  bool isProfileCompleted = false,
  int? aiGenerationsRemaining,
}) {
  return User(
    id: id,
    email: email,
    fullName: fullName,
    plan: plan,
    isProfileCompleted: isProfileCompleted,
    createdAt: DateTime(2024),
    aiGenerationsRemaining: aiGenerationsRemaining,
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

Activity makeActivity({
  String id = 'act-1',
  String tripId = 'trip-1',
  String title = 'Visit Eiffel Tower',
  DateTime? date,
  String? startTime = '09:00',
  ActivityCategory category = ActivityCategory.culture,
  ValidationStatus validationStatus = ValidationStatus.manual,
}) {
  return Activity(
    id: id,
    tripId: tripId,
    title: title,
    date: date ?? DateTime(2024, 6),
    startTime: startTime,
    category: category,
    validationStatus: validationStatus,
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

Accommodation makeAccommodation({
  String id = 'acc-1',
  String tripId = 'trip-1',
  String name = 'Hotel Paris',
}) {
  return Accommodation(id: id, tripId: tripId, name: name);
}

BaggageItem makeBaggageItem({
  String id = 'bag-1',
  String tripId = 'trip-1',
  String name = 'Passport',
  bool isPacked = false,
  String? category,
}) {
  return BaggageItem(
    id: id,
    tripId: tripId,
    name: name,
    isPacked: isPacked,
    category: category,
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

PaginatedResponse<T> makePaginatedResponse<T>({
  required List<T> items,
  int? total,
  int page = 1,
  int totalPages = 1,
}) {
  return PaginatedResponse<T>(
    items: items,
    total: total ?? items.length,
    page: page,
    totalPages: totalPages,
  );
}

// ─── Composite trip fixtures ────────────────────────────────────────────────

Trip makeBarcelonaTrip() => makeTrip(
  id: 'trip-barcelona',
  title: 'Barcelona Adventure',
  status: TripStatus.planned,
  destinationName: 'Barcelona',
  startDate: DateTime(2026, 4, 15),
  endDate: DateTime(2026, 4, 22),
);

Trip makeLisbonTrip() => makeTrip(
  id: 'trip-lisbon',
  title: 'Lisbon Trip',
  status: TripStatus.planned,
  destinationName: 'Lisbon',
  startDate: DateTime(2026, 6),
  endDate: DateTime(2026, 6, 7),
);

Trip makeActiveTripToday() {
  final now = DateTime.now();
  return makeTrip(
    id: 'trip-active',
    title: 'Active Trip',
    status: TripStatus.ongoing,
    destinationName: 'Barcelona',
    startDate: DateTime(now.year, now.month, now.day),
    endDate: DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 5)),
  );
}

Trip makeEndedTrip() {
  final now = DateTime.now();
  return makeTrip(
    id: 'trip-ended',
    title: 'Ended Trip',
    status: TripStatus.ongoing,
    startDate: DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 7)),
    endDate: DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1)),
  );
}

// ─── Stubbing helpers ───────────────────────────────────────────────────────

/// Stubs auth as authenticated with a default user.
void stubAuthenticated(MockContainer mocks, {User? user}) {
  final u = user ?? makeUser();
  when(
    () => mocks.auth.isAuthenticated(),
  ).thenAnswer((_) async => const Success(true));
  when(() => mocks.auth.getCurrentUser()).thenAnswer((_) async => Success(u));
  when(
    () => mocks.storage.getAccessToken(),
  ).thenAnswer((_) async => 'test-token');
}

/// Stubs home with no trips → HomeNewUser.
void stubEmptyHome(MockContainer mocks) {
  _stubTripsPaginated(mocks);
}

/// Stubs home with an ongoing trip → HomeActiveTrip.
void stubActiveTripHome(
  MockContainer mocks,
  Trip activeTrip, {
  List<Activity> activities = const [],
  WeatherSummary? weather,
}) {
  _stubTripsPaginated(mocks, ongoing: [activeTrip]);

  when(
    () => mocks.activity.getActivities(activeTrip.id),
  ).thenAnswer((_) async => Success(activities));

  if (weather != null) {
    when(
      () => mocks.weather.getWeather(activeTrip.id),
    ).thenAnswer((_) async => Success(weather));
  } else {
    when(
      () => mocks.weather.getWeather(activeTrip.id),
    ).thenAnswer((_) async => const Failure(NetworkError('no weather')));
  }
}

/// Stubs home with planned/completed trips → HomeTripManager.
void stubTripManagerHome(
  MockContainer mocks, {
  List<Trip> planned = const [],
  List<Trip> completed = const [],
}) {
  _stubTripsPaginated(mocks, planned: planned, completed: completed);
}

void _stubTripsPaginated(
  MockContainer mocks, {
  List<Trip> ongoing = const [],
  List<Trip> planned = const [],
  List<Trip> completed = const [],
}) {
  // Catch-all FIRST (mocktail: last registered wins, so specifics override)
  when(
    () => mocks.trip.getTripsPaginated(
      status: any(named: 'status'),
      limit: any(named: 'limit'),
      page: any(named: 'page'),
    ),
  ).thenAnswer((_) async => Success(makePaginatedResponse(items: <Trip>[])));

  // HomeBloc calls (limit: 5)
  when(
    () => mocks.trip.getTripsPaginated(status: 'ongoing', limit: 5),
  ).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: ongoing, total: ongoing.length)),
  );
  when(
    () => mocks.trip.getTripsPaginated(status: 'planned', limit: 5),
  ).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: planned, total: planned.length)),
  );
  when(
    () => mocks.trip.getTripsPaginated(status: 'completed', limit: 5),
  ).thenAnswer(
    (_) async => Success(
      makePaginatedResponse(items: completed, total: completed.length),
    ),
  );

  // TripManagementBloc calls (default limit=20, page=1)
  when(() => mocks.trip.getTripsPaginated(status: 'ongoing')).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: ongoing, total: ongoing.length)),
  );
  when(() => mocks.trip.getTripsPaginated(status: 'planned')).thenAnswer(
    (_) async =>
        Success(makePaginatedResponse(items: planned, total: planned.length)),
  );
  when(() => mocks.trip.getTripsPaginated(status: 'completed')).thenAnswer(
    (_) async => Success(
      makePaginatedResponse(items: completed, total: completed.length),
    ),
  );
}
