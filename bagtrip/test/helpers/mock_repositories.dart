import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/crashlytics_service.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/budget_repository.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/repositories/traveler_repository.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bagtrip/repositories/notification_repository.dart';
import 'package:bagtrip/repositories/booking_repository.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';
import 'package:bagtrip/repositories/subscription_repository.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bagtrip/core/cache/cache_service.dart';
import 'package:bagtrip/core/cache/connectivity_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTripRepository extends Mock implements TripRepository {}

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockAccommodationRepository extends Mock
    implements AccommodationRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockBaggageRepository extends Mock implements BaggageRepository {}

class MockTravelerRepository extends Mock implements TravelerRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockTripShareRepository extends Mock implements TripShareRepository {}

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

class MockAiRepository extends Mock implements AiRepository {}

class MockCrashlyticsService extends Mock implements CrashlyticsService {}

class MockCacheService extends Mock implements CacheService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockTransportRepository extends Mock implements TransportRepository {}
