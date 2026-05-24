import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/notifications/cubit/notification_count_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockNotificationRepository repo;

  setUp(() => repo = MockNotificationRepository());

  blocTest<NotificationCountCubit, int>(
    'refresh() emits the unread count fetched from the repository',
    build: () {
      when(
        () => repo.getUnreadCount(),
      ).thenAnswer((_) async => const Success(7));
      return NotificationCountCubit(repository: repo);
    },
    act: (cubit) => cubit.refresh(),
    expect: () => [7],
  );

  blocTest<NotificationCountCubit, int>(
    'refresh() emits nothing when the repository fails',
    build: () {
      when(
        () => repo.getUnreadCount(),
      ).thenAnswer((_) async => const Failure(NetworkError('offline')));
      return NotificationCountCubit(repository: repo);
    },
    act: (cubit) => cubit.refresh(),
    expect: () => <int>[],
  );

  blocTest<NotificationCountCubit, int>(
    'setCount() emits the given count without hitting the repository',
    build: () => NotificationCountCubit(repository: repo),
    act: (cubit) => cubit.setCount(4),
    expect: () => [4],
    verify: (_) => verifyNever(() => repo.getUnreadCount()),
  );

  blocTest<NotificationCountCubit, int>(
    'clear() resets the count to zero',
    build: () => NotificationCountCubit(repository: repo),
    seed: () => 9,
    act: (cubit) => cubit.clear(),
    expect: () => [0],
  );
}
