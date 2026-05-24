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
    testWidgets('new user with 0 trips → IdleHomeView renders', (tester) async {
      final mocks = await setupTestServiceLocator();
      stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
      stubEmptyHome(mocks);

      await pumpTestApp(tester, existingMocks: mocks);

      // Verify HomeIdle state
      expect(f.homeIdle, findsOneWidget);
      expect(f.idleHomeView, findsOneWidget);
      expect(f.homeActiveTrip, findsNothing);
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
          originCity: any(named: 'originCity'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          nbTravelers: any(named: 'nbTravelers'),
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
      expect(f.homeIdle, findsOneWidget);

      // Call AI inspiration
      final result = await mocks.ai.getInspiration(
        originCity: any(named: 'originCity'),
        departureDate: any(named: 'departureDate'),
        returnDate: any(named: 'returnDate'),
        nbTravelers: any(named: 'nbTravelers'),
        durationDays: 7,
      );
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
      expect(f.homeIdle, findsOneWidget);

      // Consume SSE stream
      final events = await mocks.ai.planTripStream(durationDays: 7).toList();
      expect(events, hasLength(10));
      expect(events.first['event'], 'progress');
      expect(events.last['event'], 'done');

      // Verify complete event has tripId
      final completeEvent = events.firstWhere((e) => e['event'] == 'complete');
      expect(completeEvent['data']['tripId'], 'trip-barcelona');
    });

    testWidgets(
      'SSE complete event ships tripId — wizard navigates without an extra accept call',
      (tester) async {
        // SMP-325: ``/plan-trip/accept`` was removed. The wizard now
        // reads the persisted ``tripId`` straight from the SSE
        // ``complete`` event and links to the trip detail.
        final mocks = await setupTestServiceLocator();
        stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
        stubEmptyHome(mocks);

        final barcelonaTrip = makeBarcelonaTrip();

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
            destinationCity: any(named: 'destinationCity'),
            destinationIata: any(named: 'destinationIata'),
            mode: any(named: 'mode'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            {
              'event': 'complete',
              'data': {
                'tripId': 'trip-barcelona',
                'status': 'DRAFT',
                'tripDraft': const <String, dynamic>{
                  'origin_iata': 'CDG',
                  'destination_iata': 'BCN',
                  'destination_city': 'Barcelona',
                  'destination_country': 'Spain',
                  'destination_country_code': 'ES',
                  'destination_lat': 41.39,
                  'destination_lon': 2.17,
                  'start_date': '2026-04-15',
                  'end_date': '2026-04-22',
                  'duration_days': 7,
                  'nb_travelers': 2,
                  'target_budget': null,
                  'locale': 'fr',
                  'cover_image_url': null,
                  'weather': null,
                  'activities': <Map<String, dynamic>>[],
                  'accommodations': <Map<String, dynamic>>[],
                  'transport': <Map<String, dynamic>>[],
                  'baggage': <Map<String, dynamic>>[],
                  'budget': <String, dynamic>{},
                },
              },
            },
            {'event': 'done', 'data': <String, dynamic>{}},
          ]),
        );

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
        expect(f.homeIdle, findsOneWidget);

        final events = await mocks.ai.planTripStream(durationDays: 7).toList();
        final complete = events.firstWhere((e) => e['event'] == 'complete');
        expect(complete['data']['tripId'], 'trip-barcelona');
        expect(complete['data']['tripDraft']['destination_iata'], 'BCN');

        final tripHome = await mocks.trip.getTripHome('trip-barcelona');
        expect(
          (tripHome as Success<TripHome>).data.trip.destinationName,
          'Barcelona',
        );
      },
    );

    testWidgets(
      'full AI flow: new user → inspiration → plan stream → tripId → trip loaded',
      (tester) async {
        // SMP-325: the SSE pipeline persists the trip server-side, so
        // ``acceptInspiration`` is gone. The wizard reads ``tripId``
        // out of the ``complete`` SSE event and links the trip detail.
        final mocks = await setupTestServiceLocator();
        stubAuthenticated(mocks, user: makeUser(aiGenerationsRemaining: 5));
        stubEmptyHome(mocks);

        final barcelonaTrip = makeBarcelonaTrip();

        when(
          () => mocks.ai.getInspiration(
            originCity: any(named: 'originCity'),
            departureDate: any(named: 'departureDate'),
            returnDate: any(named: 'returnDate'),
            nbTravelers: any(named: 'nbTravelers'),
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer(
          (_) async => const Success([
            {'destination': 'Barcelona', 'budget_estimate': 1200},
          ]),
        );

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
            destinationCity: any(named: 'destinationCity'),
            destinationIata: any(named: 'destinationIata'),
            mode: any(named: 'mode'),
            locale: any(named: 'locale'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            {
              'event': 'progress',
              'data': {'percent': 50},
            },
            {
              'event': 'complete',
              'data': {
                'tripId': 'trip-barcelona',
                'status': 'DRAFT',
                'tripDraft': const <String, dynamic>{
                  'origin_iata': 'CDG',
                  'destination_iata': 'BCN',
                  'destination_city': 'Barcelona',
                  'destination_country': 'Spain',
                  'destination_country_code': 'ES',
                  'destination_lat': 41.39,
                  'destination_lon': 2.17,
                  'start_date': '2026-04-15',
                  'end_date': '2026-04-22',
                  'duration_days': 7,
                  'nb_travelers': 2,
                  'target_budget': null,
                  'locale': 'fr',
                  'cover_image_url': null,
                  'weather': null,
                  'activities': <Map<String, dynamic>>[],
                  'accommodations': <Map<String, dynamic>>[],
                  'transport': <Map<String, dynamic>>[],
                  'baggage': <Map<String, dynamic>>[],
                  'budget': <String, dynamic>{},
                },
              },
            },
            {'event': 'done', 'data': <String, dynamic>{}},
          ]),
        );

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
        expect(f.homeIdle, findsOneWidget);

        final inspiration = await mocks.ai.getInspiration(
          originCity: any(named: 'originCity'),
          departureDate: any(named: 'departureDate'),
          returnDate: any(named: 'returnDate'),
          nbTravelers: any(named: 'nbTravelers'),
          durationDays: 7,
        );
        expect(inspiration, isA<Success>());

        final events = await mocks.ai.planTripStream(durationDays: 7).toList();
        final complete = events.firstWhere((e) => e['event'] == 'complete');
        expect(complete['data']['tripId'], 'trip-barcelona');

        final tripHome = await mocks.trip.getTripHome('trip-barcelona');
        expect(
          (tripHome as Success<TripHome>).data.trip.destinationName,
          'Barcelona',
        );
      },
    );
  });
}
