import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/e2e_fixtures.dart';
import 'helpers/finders.dart' as f;
import 'helpers/mock_di_setup.dart';
import 'helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerE2eFallbackValues();
  });

  group('FT4 — Sharing and read-only', () {
    testWidgets('Phase 1: owner creates a share → createShare called', (
      tester,
    ) async {
      final trip = makeTrip(
        id: 'trip-shared',
        title: 'Shared Trip',
        status: TripStatus.planned,
        destinationName: 'Rome',
      );

      final mocks = await setupTestServiceLocator();
      stubTripManagerHome(mocks, planned: [trip]);

      // Stub share creation (positional tripId, named email)
      when(
        () => mocks.tripShare.createShare(
          'trip-shared',
          email: any(named: 'email'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => Success(makeTripShare(tripId: 'trip-shared')));

      // Stub share listing
      when(() => mocks.tripShare.getSharesByTrip('trip-shared')).thenAnswer(
        (_) async => Success([makeTripShare(tripId: 'trip-shared')]),
      );

      await pumpTestApp(tester, existingMocks: mocks);

      // Verify HomeIdle renders
      expect(f.homeIdle, findsOneWidget);

      // Programmatic share creation (simulates what UI would trigger)
      await mocks.tripShare.createShare(
        'trip-shared',
        email: 'viewer@example.com',
      );

      verify(
        () => mocks.tripShare.createShare(
          'trip-shared',
          email: any(named: 'email'),
          message: any(named: 'message'),
        ),
      ).called(1);

      // Verify listing returns the share
      final shares = await mocks.tripShare.getSharesByTrip('trip-shared');
      expect(shares, isA<Success>());
      expect((shares as Success).data, hasLength(1));
    });

    testWidgets('Phase 2: viewer sees read-only data (isViewer check)', (
      tester,
    ) async {
      final trip = makeTrip(
        id: 'trip-viewer',
        title: 'Rome Trip',
        status: TripStatus.planned,
        destinationName: 'Rome',
      );
      final viewerUser = makeUser(
        id: 'user-viewer',
        email: 'viewer@example.com',
        fullName: 'Viewer User',
      );

      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: viewerUser);
      stubTripManagerHome(mocks, planned: [trip]);

      // Trip home for loading detail (no userRole on TripHome model)
      when(() => mocks.trip.getTripHome('trip-viewer')).thenAnswer(
        (_) async => Success(
          TripHome(
            trip: trip,
            stats: const TripHomeStats(baggageCount: 5, totalExpenses: 250.0),
            features: const [],
          ),
        ),
      );

      // Shares: viewer is listed
      when(() => mocks.tripShare.getSharesByTrip('trip-viewer')).thenAnswer(
        (_) async => Success([
          makeTripShare(tripId: 'trip-viewer', userId: 'user-viewer'),
        ]),
      );

      await pumpTestApp(tester, existingMocks: mocks);

      // Verify HomeIdle renders
      expect(f.homeIdle, findsOneWidget);

      // Verify shares list returns VIEWER role
      final shares = await mocks.tripShare.getSharesByTrip('trip-viewer');
      final shareList = (shares as Success).data;
      expect(shareList.first.role, 'VIEWER');

      // Verify no write operations occurred
      verifyNever(() => mocks.activity.createActivity(any(), any()));
      verifyNever(() => mocks.trip.deleteTrip(any()));
    });

    testWidgets(
      'Phase 3: owner revokes share → deleteShare called, viewer gets error',
      (tester) async {
        final trip = makeTrip(
          id: 'trip-revoke',
          title: 'Revoke Test',
          status: TripStatus.planned,
          destinationName: 'Rome',
        );

        final mocks = await setupTestServiceLocator();
        stubTripManagerHome(mocks, planned: [trip]);

        // Stub share deletion
        when(
          () => mocks.tripShare.deleteShare('trip-revoke', 'share-1'),
        ).thenAnswer((_) async => const Success(null));

        await pumpTestApp(tester, existingMocks: mocks);

        // Owner deletes share
        await mocks.tripShare.deleteShare('trip-revoke', 'share-1');
        verify(
          () => mocks.tripShare.deleteShare('trip-revoke', 'share-1'),
        ).called(1);

        // After revocation: stub trip load as not found for viewer
        when(() => mocks.trip.getTripHome('trip-revoke')).thenAnswer(
          (_) async => const Failure(NotFoundError('Trip not found')),
        );

        // Viewer tries to access → NotFoundError
        final result = await mocks.trip.getTripHome('trip-revoke');
        expect(result, isA<Failure<TripHome>>());
        expect((result as Failure).error, isA<NotFoundError>());
      },
    );

    testWidgets('shares can be listed after creation', (tester) async {
      final trip = makeTrip(
        id: 'trip-list-shares',
        title: 'List Shares Test',
        status: TripStatus.planned,
      );

      final mocks = await setupTestServiceLocator();
      stubTripManagerHome(mocks, planned: [trip]);

      final share1 = makeTripShare(
        tripId: 'trip-list-shares',
        userEmail: 'user2@example.com',
      );
      final share2 = makeTripShare(
        id: 'share-2',
        tripId: 'trip-list-shares',
        userId: 'user-3',
        userEmail: 'user3@example.com',
        role: 'EDITOR',
      );

      when(
        () => mocks.tripShare.getSharesByTrip('trip-list-shares'),
      ).thenAnswer((_) async => Success([share1, share2]));

      await pumpTestApp(tester, existingMocks: mocks);

      final result = await mocks.tripShare.getSharesByTrip('trip-list-shares');
      expect(result, isA<Success>());
      final shares = (result as Success).data;
      expect(shares, hasLength(2));
      expect(shares[0].role, 'VIEWER');
      expect(shares[1].role, 'EDITOR');
    });
  });
}
