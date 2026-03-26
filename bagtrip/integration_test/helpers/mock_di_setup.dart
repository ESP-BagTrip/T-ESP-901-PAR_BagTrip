import 'dart:async';

import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/repositories.dart';
import 'package:bagtrip/service/agent_service.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:bagtrip/service/trip_notification_scheduler.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mock declarations ──────────────────────────────────────────────────────
// Repositories
class MockAuthRepository extends Mock implements AuthRepository {}

class MockTripRepository extends Mock implements TripRepository {}

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockAccommodationRepository extends Mock
    implements AccommodationRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockBaggageRepository extends Mock implements BaggageRepository {}

class MockTripShareRepository extends Mock implements TripShareRepository {}

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

class MockAiRepository extends Mock implements AiRepository {}

class MockTransportRepository extends Mock implements TransportRepository {}

class MockWeatherRepository extends Mock implements WeatherRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockTravelerRepository extends Mock implements TravelerRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

// Services
class MockStorageService extends Mock implements StorageService {}

class MockApiClient extends Mock implements ApiClient {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class MockPersonalizationStorage extends Mock
    implements PersonalizationStorage {}

class MockLocationService extends Mock implements LocationService {}

class MockTripNotificationScheduler extends Mock
    implements TripNotificationScheduler {}

class MockPostTripDismissalStorage extends Mock
    implements PostTripDismissalStorage {}

class MockOnboardingStorage extends Mock implements OnboardingStorage {}

class MockAgentService extends Mock implements AgentService {}

// ─── Container ──────────────────────────────────────────────────────────────

class MockContainer {
  // Repositories
  final MockAuthRepository auth;
  final MockTripRepository trip;
  final MockActivityRepository activity;
  final MockAccommodationRepository accommodation;
  final MockBudgetRepository budget;
  final MockBaggageRepository baggage;
  final MockTripShareRepository tripShare;
  final MockFeedbackRepository feedback;
  final MockAiRepository ai;
  final MockTransportRepository transport;
  final MockWeatherRepository weather;
  final MockNotificationRepository notification;
  final MockBookingRepository booking;
  final MockProfileRepository profile;
  final MockTravelerRepository traveler;
  final MockSubscriptionRepository subscription;

  // Services
  final MockStorageService storage;
  final MockApiClient apiClient;
  final MockCacheService cache;
  final MockConnectivityService connectivity;
  final MockCrashlyticsService crashlytics;
  final MockPersonalizationStorage personalization;
  final MockLocationService location;
  final MockTripNotificationScheduler scheduler;
  final MockPostTripDismissalStorage dismissalStorage;
  final MockOnboardingStorage onboardingStorage;
  final MockAgentService agentService;

  MockContainer({
    required this.auth,
    required this.trip,
    required this.activity,
    required this.accommodation,
    required this.budget,
    required this.baggage,
    required this.tripShare,
    required this.feedback,
    required this.ai,
    required this.transport,
    required this.weather,
    required this.notification,
    required this.booking,
    required this.profile,
    required this.traveler,
    required this.subscription,
    required this.storage,
    required this.apiClient,
    required this.cache,
    required this.connectivity,
    required this.crashlytics,
    required this.personalization,
    required this.location,
    required this.scheduler,
    required this.dismissalStorage,
    required this.onboardingStorage,
    required this.agentService,
  });
}

// ─── Setup ──────────────────────────────────────────────────────────────────

/// Must be called once (e.g. in setUpAll) before using [setupTestServiceLocator].
void registerE2eFallbackValues() {
  registerFallbackValue(const Trip(id: '', userId: ''));
  registerFallbackValue(const UnknownError('fallback'));
  registerFallbackValue(StackTrace.empty);
  registerFallbackValue(<String, dynamic>{});
}

Future<MockContainer> setupTestServiceLocator() async {
  await getIt.reset();

  final mocks = MockContainer(
    auth: MockAuthRepository(),
    trip: MockTripRepository(),
    activity: MockActivityRepository(),
    accommodation: MockAccommodationRepository(),
    budget: MockBudgetRepository(),
    baggage: MockBaggageRepository(),
    tripShare: MockTripShareRepository(),
    feedback: MockFeedbackRepository(),
    ai: MockAiRepository(),
    transport: MockTransportRepository(),
    weather: MockWeatherRepository(),
    notification: MockNotificationRepository(),
    booking: MockBookingRepository(),
    profile: MockProfileRepository(),
    traveler: MockTravelerRepository(),
    subscription: MockSubscriptionRepository(),
    storage: MockStorageService(),
    apiClient: MockApiClient(),
    cache: MockCacheService(),
    connectivity: MockConnectivityService(),
    crashlytics: MockCrashlyticsService(),
    personalization: MockPersonalizationStorage(),
    location: MockLocationService(),
    scheduler: MockTripNotificationScheduler(),
    dismissalStorage: MockPostTripDismissalStorage(),
    onboardingStorage: MockOnboardingStorage(),
    agentService: MockAgentService(),
  );

  // Layer 1: Leaf services
  getIt.registerLazySingleton<StorageService>(() => mocks.storage);
  getIt.registerLazySingleton<OnboardingStorage>(() => mocks.onboardingStorage);
  getIt.registerLazySingleton<PostTripDismissalStorage>(
    () => mocks.dismissalStorage,
  );
  getIt.registerLazySingleton<PersonalizationStorage>(
    () => mocks.personalization,
  );
  getIt.registerLazySingleton<CrashlyticsService>(() => mocks.crashlytics);
  getIt.registerLazySingleton<CacheService>(() => mocks.cache);
  getIt.registerLazySingleton<ConnectivityService>(() => mocks.connectivity);

  // Layer 2: ApiClient
  getIt.registerLazySingleton<ApiClient>(() => mocks.apiClient);

  // Layer 3: Repositories
  getIt.registerLazySingleton<AuthRepository>(() => mocks.auth);
  getIt.registerLazySingleton<NotificationRepository>(() => mocks.notification);
  getIt.registerLazySingleton<ProfileRepository>(() => mocks.profile);
  getIt.registerLazySingleton<BookingRepository>(() => mocks.booking);
  getIt.registerLazySingleton<ActivityRepository>(() => mocks.activity);
  getIt.registerLazySingleton<BudgetRepository>(() => mocks.budget);
  getIt.registerLazySingleton<TripRepository>(() => mocks.trip);
  getIt.registerLazySingleton<TripShareRepository>(() => mocks.tripShare);
  getIt.registerLazySingleton<AccommodationRepository>(
    () => mocks.accommodation,
  );
  getIt.registerLazySingleton<BaggageRepository>(() => mocks.baggage);
  getIt.registerLazySingleton<TravelerRepository>(() => mocks.traveler);
  getIt.registerLazySingleton<AgentService>(() => mocks.agentService);
  getIt.registerLazySingleton<FeedbackRepository>(() => mocks.feedback);
  getIt.registerLazySingleton<SubscriptionRepository>(() => mocks.subscription);
  getIt.registerLazySingleton<AiRepository>(() => mocks.ai);
  getIt.registerLazySingleton<TransportRepository>(() => mocks.transport);
  getIt.registerLazySingleton<WeatherRepository>(() => mocks.weather);

  // Layer 5: Composite services
  getIt.registerLazySingleton<TripNotificationScheduler>(() => mocks.scheduler);
  getIt.registerLazySingleton<LocationService>(() => mocks.location);

  // ── Universal stubs (safe defaults) ──
  when(() => mocks.connectivity.isOnline).thenReturn(true);
  when(
    () => mocks.connectivity.onConnectivityChanged,
  ).thenAnswer((_) => const Stream<bool>.empty());
  when(() => mocks.crashlytics.setUserId(any())).thenAnswer((_) async {});
  when(() => mocks.crashlytics.clearUserId()).thenAnswer((_) async {});
  when(
    () => mocks.crashlytics.recordAppError(
      any(),
      stackTrace: any(named: 'stackTrace'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => mocks.scheduler.scheduleOngoingNotifications(any()),
  ).thenAnswer((_) async {});
  when(
    () => mocks.scheduler.schedulePackingReminder(any()),
  ).thenAnswer((_) async {});
  when(
    () => mocks.scheduler.cancelTripNotifications(any()),
  ).thenAnswer((_) async {});
  when(
    () => mocks.scheduler.scheduleCompletionReminder(any()),
  ).thenAnswer((_) async {});
  when(
    () => mocks.dismissalStorage.wasDismissedRecently(any()),
  ).thenAnswer((_) async => false);
  when(
    () => mocks.dismissalStorage.recordDismissal(any()),
  ).thenAnswer((_) async {});
  when(
    () => mocks.dismissalStorage.clearDismissal(any()),
  ).thenAnswer((_) async {});

  // Stubs for PostTripBloc (navigated to on trip completion)
  when(
    () => mocks.trip.getTripById(any()),
  ).thenAnswer((_) async => const Success(Trip(id: '', userId: '')));
  when(
    () => mocks.activity.getActivities(any()),
  ).thenAnswer((_) async => const Success([]));
  when(
    () => mocks.budget.getBudgetSummary(any()),
  ).thenAnswer((_) async => const Failure(NetworkError('no budget')));

  return mocks;
}
