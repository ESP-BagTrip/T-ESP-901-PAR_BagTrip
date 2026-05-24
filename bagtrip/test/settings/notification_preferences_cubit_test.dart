import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/notification_preferences.dart';
import 'package:bagtrip/settings/cubit/notification_preferences_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockNotificationRepository mockRepo;

  const loadedPrefs = NotificationPreferences();

  setUpAll(() {
    registerFallbackValue(const NotificationPreferences());
  });

  setUp(() {
    mockRepo = MockNotificationRepository();
  });

  group('load', () {
    blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
      'emits [Loading, Loaded] on success',
      setUp: () {
        when(
          () => mockRepo.getNotificationPreferences(),
        ).thenAnswer((_) async => const Success(loadedPrefs));
      },
      build: () => NotificationPreferencesCubit(repo: mockRepo),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationPreferencesLoading>(),
        isA<NotificationPreferencesLoaded>(),
      ],
    );

    blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
      'emits [Loading, Error] on failure',
      setUp: () {
        when(
          () => mockRepo.getNotificationPreferences(),
        ).thenAnswer((_) async => const Failure(UnknownError('boom')));
      },
      build: () => NotificationPreferencesCubit(repo: mockRepo),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<NotificationPreferencesLoading>(),
        isA<NotificationPreferencesError>(),
      ],
    );
  });

  group('toggle', () {
    blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
      'optimistically updates then confirms on success',
      setUp: () {
        when(
          () => mockRepo.getNotificationPreferences(),
        ).thenAnswer((_) async => const Success(loadedPrefs));
        when(() => mockRepo.updateNotificationPreferences(any())).thenAnswer(
          (_) async =>
              const Success(NotificationPreferences(flightReminders: false)),
        );
      },
      build: () => NotificationPreferencesCubit(repo: mockRepo),
      act: (cubit) async {
        await cubit.load();
        await cubit.toggle(NotificationPreferenceField.flightReminders, false);
      },
      verify: (cubit) {
        final state = cubit.state as NotificationPreferencesLoaded;
        expect(state.preferences.flightReminders, false);
        expect(state.operationError, isNull);
      },
    );

    blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
      'rolls back to previous value and surfaces error on failure',
      setUp: () {
        when(
          () => mockRepo.getNotificationPreferences(),
        ).thenAnswer((_) async => const Success(loadedPrefs));
        when(
          () => mockRepo.updateNotificationPreferences(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('offline')));
      },
      build: () => NotificationPreferencesCubit(repo: mockRepo),
      act: (cubit) async {
        await cubit.load();
        await cubit.toggle(NotificationPreferenceField.budgetAlerts, false);
      },
      verify: (cubit) {
        final state = cubit.state as NotificationPreferencesLoaded;
        // Rolled back to the original (default true).
        expect(state.preferences.budgetAlerts, true);
        expect(state.operationError, isA<NetworkError>());
      },
    );

    test('is a no-op when state is not loaded', () async {
      final cubit = NotificationPreferencesCubit(repo: mockRepo);
      await cubit.toggle(NotificationPreferenceField.pushEnabled, false);
      expect(cubit.state, isA<NotificationPreferencesInitial>());
      verifyNever(() => mockRepo.updateNotificationPreferences(any()));
      await cubit.close();
    });
  });
}
