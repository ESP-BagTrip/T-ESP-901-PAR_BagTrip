import 'package:get_it/get_it.dart';

import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/service/storage_service.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/auth_service.dart';
import 'package:bagtrip/service/notification_service.dart';
import 'package:bagtrip/service/profile_api_service.dart';
import 'package:bagtrip/service/booking_service.dart';
import 'package:bagtrip/service/activity_service.dart';
import 'package:bagtrip/service/activity_ai_service.dart';
import 'package:bagtrip/service/budget_service.dart';
import 'package:bagtrip/service/trip_service.dart';
import 'package:bagtrip/service/trip_share_service.dart';
import 'package:bagtrip/service/accommodation_service.dart';
import 'package:bagtrip/service/baggage_item_service.dart';
import 'package:bagtrip/service/baggage_ai_service.dart';
import 'package:bagtrip/service/traveler_service.dart';
import 'package:bagtrip/service/agent_service.dart';
import 'package:bagtrip/service/feedback_service.dart';
import 'package:bagtrip/service/subscription_service.dart';
import 'package:bagtrip/service/ai_service.dart';
import 'package:bagtrip/service/post_trip_ai_service.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bagtrip/service/onboarding_storage.dart';
import 'package:bagtrip/service/personalization_storage.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // 1. Leaf services (no API dependency)
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<OnboardingStorage>(() => OnboardingStorage());
  getIt.registerLazySingleton<PersonalizationStorage>(
    () => PersonalizationStorage(),
  );

  // 2. ApiClient (depends on StorageService)
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      storageService: getIt<StorageService>(),
    ),
  );

  // 3. AuthService (depends on ApiClient + StorageService)
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(
      apiClient: getIt<ApiClient>(),
      storageService: getIt<StorageService>(),
    ),
  );

  // 4. API services (depend on ApiClient)
  getIt.registerLazySingleton<NotificationApiService>(
    () => NotificationApiService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileApiService>(
    () => ProfileApiService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BookingService>(
    () => BookingService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ActivityService>(
    () => ActivityService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ActivityAiService>(
    () => ActivityAiService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BudgetService>(
    () => BudgetService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TripService>(
    () => TripService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TripShareService>(
    () => TripShareService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AccommodationService>(
    () => AccommodationService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BaggageItemService>(
    () => BaggageItemService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<BaggageAiService>(
    () => BaggageAiService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<TravelerService>(
    () => TravelerService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AgentService>(
    () => AgentService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<FeedbackService>(
    () => FeedbackService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SubscriptionService>(
    () => SubscriptionService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AiService>(
    () => AiService(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PostTripAiService>(
    () => PostTripAiService(apiClient: getIt<ApiClient>()),
  );

  // 5. LocationService (uses Dio directly, not ApiClient)
  getIt.registerLazySingleton<LocationService>(() => LocationService());
}
