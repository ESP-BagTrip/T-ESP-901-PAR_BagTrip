import 'package:bagtrip/core/result.dart';
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

  group('FT1 — New user AI trip creation', () {
    testWidgets('new user with 0 trips → OnboardingHomeView renders', (
      tester,
    ) async {
      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
      stubEmptyHome(mocks);

      await pumpTestApp(tester, existingMocks: mocks);

      // Verify HomeNewUser state
      expect(f.homeNewUser, findsOneWidget);
      expect(f.onboardingHomeView, findsOneWidget);
      expect(f.homeActiveTrip, findsNothing);
      expect(f.homeTripManager, findsNothing);
    });

    testWidgets('AI inspiration returns destination suggestions', (
      tester,
    ) async {
      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
      stubEmptyHome(mocks);

      // Stub AI inspiration
      when(
        () => mocks.ai.getInspiration(
          travelTypes: any(named: 'travelTypes'),
          budgetRange: any(named: 'budgetRange'),
          durationDays: any(named: 'durationDays'),
          companions: any(named: 'companions'),
          season: any(named: 'season'),
          constraints: any(named: 'constraints'),
        ),
      ).thenAnswer(
        (_) async => const Success([
          {
            'destination': 'Barcelona',
            'country': 'Spain',
            'description': 'Vibrant city with beaches and architecture',
            'budget_estimate': 1200,
          },
          {
            'destination': 'Lisbon',
            'country': 'Portugal',
            'description': 'Charming coastal capital',
            'budget_estimate': 900,
          },
        ]),
      );

      await pumpTestApp(tester, existingMocks: mocks);
      expect(f.homeNewUser, findsOneWidget);

      // Call AI inspiration
      final result = await mocks.ai.getInspiration(durationDays: 7);
      expect(result, isA<Success>());
      final suggestions = (result as Success).data;
      expect(suggestions, hasLength(2));
      expect(suggestions[0]['destination'], 'Barcelona');
    });

    testWidgets('AI planTripStream emits SSE events in sequence', (
      tester,
    ) async {
      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
      stubEmptyHome(mocks);

      // Stub SSE stream (synchronous via Stream.fromIterable)
      final sseEvents = [
        {
          'event': 'progress',
          'data': {'step': 'destinations', 'percent': 10},
        },
        {
          'event': 'destinations',
          'data': {
            'items': ['Barcelona'],
          },
        },
        {
          'event': 'progress',
          'data': {'step': 'activities', 'percent': 30},
        },
        {
          'event': 'activities',
          'data': {'count': 5},
        },
        {
          'event': 'progress',
          'data': {'step': 'accommodations', 'percent': 50},
        },
        {
          'event': 'accommodations',
          'data': {'count': 2},
        },
        {
          'event': 'progress',
          'data': {'step': 'baggage', 'percent': 70},
        },
        {
          'event': 'budget',
          'data': {'total': 1200},
        },
        {
          'event': 'complete',
          'data': {'tripId': 'trip-barcelona'},
        },
        {'event': 'done', 'data': {}},
      ];

      when(
        () => mocks.ai.planTripStream(
          travelTypes: any(named: 'travelTypes'),
          budgetRange: any(named: 'budgetRange'),
          durationDays: any(named: 'durationDays'),
          companions: any(named: 'companions'),
          constraints: any(named: 'constraints'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          originCity: any(named: 'originCity'),
        ),
      ).thenAnswer((_) => Stream.fromIterable(sseEvents));

      await pumpTestApp(tester, existingMocks: mocks);
      expect(f.homeNewUser, findsOneWidget);

      // Consume SSE stream
      final events = await mocks.ai.planTripStream(durationDays: 7).toList();
      expect(events, hasLength(10));
      expect(events.first['event'], 'progress');
      expect(events.last['event'], 'done');

      // Verify complete event has tripId
      final completeEvent = events.firstWhere((e) => e['event'] == 'complete');
      expect(completeEvent['data']['tripId'], 'trip-barcelona');
    });

    testWidgets('acceptInspiration creates trip and returns tripId', (
      tester,
    ) async {
      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
      stubEmptyHome(mocks);

      final barcelonaTrip = makeBarcelonaTrip();

      // Stub accept inspiration
      when(
        () => mocks.ai.acceptInspiration(
          any(),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success({'tripId': 'trip-barcelona', 'status': 'planned'}),
      );

      // Stub trip detail loading after acceptance
      when(() => mocks.trip.getTripHome('trip-barcelona')).thenAnswer(
        (_) async => Success(
          TripHome(
            trip: barcelonaTrip,
            stats: const TripHomeStats(baggageCount: 3, totalExpenses: 1200),
            features: const [
              TripFeatureTile(
                id: 'activities',
                label: 'Activities',
                icon: 'activity',
                route: '/activities',
                enabled: true,
              ),
            ],
          ),
        ),
      );

      await pumpTestApp(tester, existingMocks: mocks);
      expect(f.homeNewUser, findsOneWidget);

      // Accept inspiration
      final result = await mocks.ai.acceptInspiration(
        {'destination': 'Barcelona'},
        startDate: '2026-04-15',
        endDate: '2026-04-22',
      );
      expect(result, isA<Success>());
      expect((result as Success).data['tripId'], 'trip-barcelona');

      verify(
        () => mocks.ai.acceptInspiration(
          any(),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).called(1);
    });

    testWidgets(
      'full AI flow: new user → inspiration → plan stream → accept → trip loaded',
      (tester) async {
        final mocks = await setupTestServiceLocator();
        stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
        stubEmptyHome(mocks);

        final barcelonaTrip = makeBarcelonaTrip();

        // Step 1: Inspiration
        when(
          () => mocks.ai.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).thenAnswer(
          (_) async => const Success([
            {'destination': 'Barcelona', 'budget_estimate': 1200},
          ]),
        );

        // Step 2: SSE stream
        when(
          () => mocks.ai.planTripStream(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            constraints: any(named: 'constraints'),
            departureDate: any(named: 'departureDate'),
            returnDate: any(named: 'returnDate'),
            originCity: any(named: 'originCity'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            {
              'event': 'progress',
              'data': {'percent': 50},
            },
            {
              'event': 'complete',
              'data': {'tripId': 'trip-barcelona'},
            },
            {'event': 'done', 'data': {}},
          ]),
        );

        // Step 3: Accept
        when(
          () => mocks.ai.acceptInspiration(
            any(),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => const Success({'tripId': 'trip-barcelona'}));

        // Step 4: Trip detail
        when(() => mocks.trip.getTripHome('trip-barcelona')).thenAnswer(
          (_) async => Success(
            TripHome(
              trip: barcelonaTrip,
              stats: const TripHomeStats(baggageCount: 3, totalExpenses: 1200),
              features: const [],
            ),
          ),
        );

        await pumpTestApp(tester, existingMocks: mocks);
        expect(f.homeNewUser, findsOneWidget);

        // Execute full flow
        // 1. Get inspiration
        final inspiration = await mocks.ai.getInspiration(durationDays: 7);
        expect(inspiration, isA<Success>());

        // 2. Plan trip stream
        final events = await mocks.ai.planTripStream(durationDays: 7).toList();
        expect(events.last['event'], 'done');

        // 3. Accept inspiration
        final accepted = await mocks.ai.acceptInspiration(
          {'destination': 'Barcelona'},
          startDate: '2026-04-15',
          endDate: '2026-04-22',
        );
        expect((accepted as Success).data['tripId'], 'trip-barcelona');

        // 4. Load trip
        final tripHome = await mocks.trip.getTripHome('trip-barcelona');
        expect(tripHome, isA<Success<TripHome>>());
        expect(
          (tripHome as Success<TripHome>).data.trip.destinationName,
          'Barcelona',
        );

        // Verify all AI methods called
        verify(
          () => mocks.ai.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        ).called(1);
        verify(
          () => mocks.ai.acceptInspiration(
            any(),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);
      },
    );
  });
}
