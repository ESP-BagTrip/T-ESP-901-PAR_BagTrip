import 'package:bagtrip/config/service_locator.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/feedback.dart';
import 'package:bagtrip/models/user.dart';
import 'package:bagtrip/pages/feedback_page.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/ai_repository.dart';
import 'package:bagtrip/repositories/auth_repository.dart';
import 'package:bagtrip/repositories/feedback_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/pump_widget.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockFeedbackRepository mockFeedbackRepo;
  late MockAiRepository mockAiRepo;
  late MockAuthRepository mockAuthRepo;
  late MockActivityRepository mockActivityRepo;

  setUpAll(() {
    registerFallbackValue(const UnknownError(''));
  });

  setUp(() {
    mockFeedbackRepo = MockFeedbackRepository();
    mockAiRepo = MockAiRepository();
    mockAuthRepo = MockAuthRepository();
    mockActivityRepo = MockActivityRepository();

    if (getIt.isRegistered<FeedbackRepository>()) {
      getIt.unregister<FeedbackRepository>();
    }
    if (getIt.isRegistered<AiRepository>()) {
      getIt.unregister<AiRepository>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<ActivityRepository>()) {
      getIt.unregister<ActivityRepository>();
    }
    getIt.registerLazySingleton<FeedbackRepository>(() => mockFeedbackRepo);
    getIt.registerLazySingleton<AiRepository>(() => mockAiRepo);
    getIt.registerLazySingleton<AuthRepository>(() => mockAuthRepo);
    getIt.registerLazySingleton<ActivityRepository>(() => mockActivityRepo);

    when(
      () => mockFeedbackRepo.getFeedbacks(any()),
    ).thenAnswer((_) async => const Success<List<TripFeedback>>([]));
    when(
      () => mockAuthRepo.getCurrentUser(),
    ).thenAnswer((_) async => Success<User?>(makeUser()));
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success<List<Activity>>([]));
  });

  tearDown(() {
    if (getIt.isRegistered<FeedbackRepository>()) {
      getIt.unregister<FeedbackRepository>();
    }
    if (getIt.isRegistered<AiRepository>()) {
      getIt.unregister<AiRepository>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<ActivityRepository>()) {
      getIt.unregister<ActivityRepository>();
    }
  });

  group('FeedbackPage', () {
    testWidgets('renders with empty feedback list', (tester) async {
      await pumpLocalized(tester, const FeedbackPage(tripId: 'trip-1'));
      await tester.pump();
      expect(find.byType(FeedbackPage), findsOneWidget);
    });

    testWidgets('renders with loaded feedbacks', (tester) async {
      when(() => mockFeedbackRepo.getFeedbacks(any())).thenAnswer(
        (_) async => Success<List<TripFeedback>>([makeTripFeedback()]),
      );
      await pumpLocalized(tester, const FeedbackPage(tripId: 'trip-1'));
      await tester.pump();
      expect(find.byType(FeedbackPage), findsOneWidget);
    });

    testWidgets('renders when auth repo returns null user', (tester) async {
      when(
        () => mockAuthRepo.getCurrentUser(),
      ).thenAnswer((_) async => const Success<User?>(null));
      await pumpLocalized(tester, const FeedbackPage(tripId: 'trip-1'));
      await tester.pump();
      expect(find.byType(FeedbackPage), findsOneWidget);
    });
  });
}
