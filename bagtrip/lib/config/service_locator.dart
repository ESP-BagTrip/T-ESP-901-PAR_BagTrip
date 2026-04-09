import 'package:get_it/get_it.dart';

import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:bagtrip/service/profile_api_service.dart';
import 'package:bagtrip/service/booking_service.dart';
import 'package:bagtrip/service/activity_service.dart';
import 'package:bagtrip/service/budget_service.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:bagtrip/service/trip_share_service.dart';
import 'package:bagtrip/service/accommodation_service.dart';
import 'package:bagtrip/service/baggage_item_service.dart';
import 'package:bagtrip/service/traveler_service.dart';
import 'package:bagtrip/service/agent_service.dart';
import 'package:bagtrip/service/feedback_service.dart';
import 'package:bagtrip/service/subscription_service.dart';
import 'package:bagtrip/service/ai_service.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/transport_service.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:bagtrip/service/post_trip_dismissal_storage.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/service/personalization_storage.dart';
import 'package:bagtrip/service/settings_storage.dart';
import 'package:bagtrip/service/cached_trip_repository.dart';
import 'package:bagtrip/service/cached_weather_repository.dart';
import 'package:bagtrip/service/cached_activity_repository.dart';
import 'package:bagtrip/service/cached_baggage_repository.dart';
import 'package:bagtrip/service/cached_budget_repository.dart';
import 'package:bagtrip/core/cache/offline_write_queue.dart';
import 'package:bagtrip/service/weather_service.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';

import 'package:bagtrip/service/trip_notification_scheduler.dart';
import 'package:bagtrip/repositories/repositories.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // 1. Leaf services (no API dependency)
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<OnboardingStorage>(() => OnboardingStorage());
  getIt.registerLazySingleton<PostTripDismissalStorage>(
    () => PostTripDismissalStorage(),
  );
  getIt.registerLazySingleton<PersonalizationStorage>(
    () => PersonalizationStorage(),
  );
  getIt.registerLazySingleton<SettingsStorage>(() => SettingsStorage());
  getIt.registerLazySingleton<CrashlyticsService>(() => CrashlyticsService());
  getIt.registerLazySingleton<CacheService>(() => CacheService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  getIt.registerLazySingleton<OfflineWriteQueue>(
    () => OfflineWriteQueue(
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // 2. ApiClient (depends on StorageService)
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      storageService: getIt<StorageService>(),
    ),
  );

  // 3. AuthRepository (depends on ApiClient + StorageService)
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // 4. Domain repositories (depend on ApiClient)
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ActivityRepository>(
    () => CachedActivityRepository(
      remote: ActivityRepositoryImpl(apiClient: getIt<ApiClient>()),
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
      queue: getIt<OfflineWriteQueue>(),
    ),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => CachedBudgetRepository(
      remote: BudgetRepositoryImpl(apiClient: getIt<ApiClient>()),
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
      queue: getIt<OfflineWriteQueue>(),
    ),
  );
  getIt.registerLazySingleton<TripRepository>(
    () => CachedTripRepository(
      remote: TripRepositoryImpl(apiClient: getIt<ApiClient>()),
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );
  getIt.registerLazySingleton<TripShareRepository>(
    () => TripShareRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AccommodationRepository>(
    () => AccommodationRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BaggageRepository>(
    () => CachedBaggageRepository(
      remote: BaggageRepositoryImpl(apiClient: getIt<ApiClient>()),
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
      queue: getIt<OfflineWriteQueue>(),
    ),
  );
  getIt.registerLazySingleton<TravelerRepository>(
    () => TravelerRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AgentService>(
    () => AgentService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );
  getIt.registerLazySingleton<TransportRepository>(
    () => TransportRepositoryImpl(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<WeatherRepository>(
    () => CachedWeatherRepository(
      remote: WeatherRepositoryImpl(apiClient: getIt<ApiClient>()),
      cache: getIt<CacheService>(),
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // 5. TripNotificationScheduler
  getIt.registerLazySingleton<TripNotificationScheduler>(
    () => TripNotificationScheduler(
      activityRepository: getIt<ActivityRepository>(),
      accommodationRepository: getIt<AccommodationRepository>(),
      baggageRepository: getIt<BaggageRepository>(),
    ),
  );

  // 6. LocationService (uses Dio directly, not ApiClient)
  getIt.registerLazySingleton<LocationService>(() => LocationService());
}
