import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/models/activity.dart';
import 'package:bagtrip/models/baggage_item.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/repositories/activity_repository.dart';
import 'package:bagtrip/repositories/baggage_repository.dart';
import 'package:bagtrip/service/trip_notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;

class MockActivityRepository extends Mock implements ActivityRepository {}

class MockAccommodationRepository extends Mock
    implements AccommodationRepository {}

class MockBaggageRepository extends Mock implements BaggageRepository {}

class MockNotificationScheduleService extends Mock
    implements NotificationScheduleService {}

void main() {
  late MockActivityRepository mockActivityRepo;
  late MockAccommodationRepository mockAccommodationRepo;
  late MockBaggageRepository mockBaggageRepo;
  late MockNotificationScheduleService mockNotifService;
  late TripNotificationScheduler scheduler;

  setUpAll(() {
    tz.initializeTimeZones();
    tzlib.setLocalLocation(tzlib.getLocation('Europe/Paris'));
    registerFallbackValue(tzlib.TZDateTime.now(tzlib.local));
  });

  setUp(() {
    mockActivityRepo = MockActivityRepository();
    mockAccommodationRepo = MockAccommodationRepository();
    mockBaggageRepo = MockBaggageRepository();
    mockNotifService = MockNotificationScheduleService();

    when(() => mockNotifService.cancel(any())).thenAnswer((_) async {});
    when(
      () => mockNotifService.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    scheduler = TripNotificationScheduler(
      activityRepository: mockActivityRepo,
      accommodationRepository: mockAccommodationRepo,
      baggageRepository: mockBaggageRepo,
      notificationService: mockNotifService,
    );
  });

  group('stableId', () {
    test('returns deterministic value for same input', () {
      final id1 = TripNotificationScheduler.stableId('daily_trip1_1');
      final id2 = TripNotificationScheduler.stableId('daily_trip1_1');
      expect(id1, equals(id2));
    });

    test('returns different values for different inputs', () {
      final id1 = TripNotificationScheduler.stableId('daily_trip1_1');
      final id2 = TripNotificationScheduler.stableId('daily_trip1_2');
      expect(id1, isNot(equals(id2)));
    });

    test('returns positive 31-bit int', () {
      final id = TripNotificationScheduler.stableId('activity_abc123');
      expect(id, greaterThan(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });

    test('handles empty string', () {
      final id = TripNotificationScheduler.stableId('');
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(0x7FFFFFFF));
    });
  });

  group('cancelTripNotifications', () {
    test('cancels all computed IDs for a trip', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime(2026, 3, 20),
        endDate: DateTime(2026, 3, 22),
        status: TripStatus.ongoing,
      );

      when(
        () => mockActivityRepo.getActivities('trip1'),
      ).thenAnswer((_) async => const Success(<Activity>[]));
      when(
        () => mockAccommodationRepo.getByTrip('trip1'),
      ).thenAnswer((_) async => const Success(<Accommodation>[]));

      await scheduler.cancelTripNotifications(trip);

      verify(() => mockActivityRepo.getActivities('trip1')).called(1);
      verify(() => mockAccommodationRepo.getByTrip('trip1')).called(1);
      // packing + 3 daily summaries = 4 cancel calls minimum
      verify(
        () => mockNotifService.cancel(any()),
      ).called(greaterThanOrEqualTo(4));
    });
  });

  group('schedulePackingReminder', () {
    test('skips if no startDate', () async {
      const trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        status: TripStatus.planned,
      );

      await scheduler.schedulePackingReminder(trip);

      verifyNever(() => mockBaggageRepo.getByTrip(any()));
    });

    test('skips if reminder date is past', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime(2020),
        status: TripStatus.planned,
      );

      await scheduler.schedulePackingReminder(trip);

      verifyNever(() => mockBaggageRepo.getByTrip(any()));
    });

    test('skips if no unpacked items', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime.now().add(const Duration(days: 10)),
        destinationName: 'Paris',
        status: TripStatus.planned,
      );

      when(() => mockBaggageRepo.getByTrip('trip1')).thenAnswer(
        (_) async => const Success([
          BaggageItem(id: 'b1', tripId: 'trip1', name: 'Shirt', isPacked: true),
          BaggageItem(id: 'b2', tripId: 'trip1', name: 'Pants', isPacked: true),
        ]),
      );

      await scheduler.schedulePackingReminder(trip);

      verify(() => mockBaggageRepo.getByTrip('trip1')).called(1);
      verifyNever(
        () => mockNotifService.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('schedules if unpacked items exist and date is future', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime.now().add(const Duration(days: 10)),
        destinationName: 'Paris',
        status: TripStatus.planned,
      );

      when(() => mockBaggageRepo.getByTrip('trip1')).thenAnswer(
        (_) async => const Success([
          BaggageItem(id: 'b1', tripId: 'trip1', name: 'Shirt'),
          BaggageItem(id: 'b2', tripId: 'trip1', name: 'Pants', isPacked: true),
        ]),
      );

      await scheduler.schedulePackingReminder(trip);

      verify(
        () => mockNotifService.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('scheduleOngoingNotifications', () {
    test('handles empty activity and accommodation lists gracefully', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        destinationName: 'Paris',
        status: TripStatus.ongoing,
      );

      // For cancelTripNotifications (called first)
      when(
        () => mockActivityRepo.getActivities('trip1'),
      ).thenAnswer((_) async => const Success(<Activity>[]));
      when(
        () => mockAccommodationRepo.getByTrip('trip1'),
      ).thenAnswer((_) async => const Success(<Accommodation>[]));

      await scheduler.scheduleOngoingNotifications(trip);

      // Called twice: once in cancel, once in schedule
      verify(() => mockActivityRepo.getActivities('trip1')).called(2);
      verify(() => mockAccommodationRepo.getByTrip('trip1')).called(2);
    });

    test('skips activities without startTime', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        destinationName: 'Paris',
        status: TripStatus.ongoing,
      );

      when(() => mockActivityRepo.getActivities('trip1')).thenAnswer(
        (_) async => Success([
          Activity(
            id: 'a1',
            tripId: 'trip1',
            title: 'No Time Activity',
            date: DateTime.now().add(const Duration(days: 1)),
            // startTime is null
          ),
        ]),
      );
      when(
        () => mockAccommodationRepo.getByTrip('trip1'),
      ).thenAnswer((_) async => const Success(<Accommodation>[]));

      await scheduler.scheduleOngoingNotifications(trip);

      verify(() => mockActivityRepo.getActivities('trip1')).called(2);
    });

    test('handles repository failures gracefully', () async {
      final trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 2)),
        destinationName: 'Paris',
        status: TripStatus.ongoing,
      );

      when(
        () => mockActivityRepo.getActivities('trip1'),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockAccommodationRepo.getByTrip('trip1'),
      ).thenAnswer((_) async => const Success(<Accommodation>[]));

      // Should not throw — errors are caught internally
      await scheduler.scheduleOngoingNotifications(trip);
    });

    test('does nothing if no startDate or endDate', () async {
      const trip = Trip(
        id: 'trip1',
        title: 'Test Trip',
        status: TripStatus.ongoing,
      );

      when(
        () => mockActivityRepo.getActivities('trip1'),
      ).thenAnswer((_) async => const Success(<Activity>[]));
      when(
        () => mockAccommodationRepo.getByTrip('trip1'),
      ).thenAnswer((_) async => const Success(<Accommodation>[]));

      await scheduler.scheduleOngoingNotifications(trip);

      // Cancel is called (which fetches repos), but no scheduling
      verifyNever(
        () => mockNotifService.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          payload: any(named: 'payload'),
        ),
      );
    });
  });
}
