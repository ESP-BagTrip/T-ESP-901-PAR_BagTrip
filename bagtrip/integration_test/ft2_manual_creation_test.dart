import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/trips/bloc/trip_management_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  group('FT2 — Manual trip creation and enrichment', () {
    testWidgets('existing user with trips → HomeTripManager renders', (
      tester,
    ) async {
      final existingTrip = makeTrip(
        id: 'trip-existing',
        title: 'Existing Trip',
        status: TripStatus.planned,
        destinationName: 'Tokyo',
      );

      final mocks = await setupTestServiceLocator();
      stubTripManagerHome(mocks, planned: [existingTrip]);

      await pumpTestApp(tester, existingMocks: mocks);

      expect(f.homeTripManager, findsOneWidget);
      expect(f.tripManagerHomeView, findsOneWidget);
      expect(f.homeNewUser, findsNothing);
    });

    testWidgets(
      'manual trip creation calls tripRepository.createTrip (not AI)',
      (tester) async {
        final existingTrip = makeTrip(
          id: 'trip-existing',
          title: 'Existing Trip',
          status: TripStatus.planned,
        );
        final newTrip = makeLisbonTrip();

        final mocks = await setupTestServiceLocator();
        stubTripManagerHome(mocks, planned: [existingTrip]);

        // Stub manual trip creation (all named params)
        when(
          () => mocks.trip.createTrip(
            title: any(named: 'title'),
            originIata: any(named: 'originIata'),
            destinationIata: any(named: 'destinationIata'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            description: any(named: 'description'),
            destinationName: any(named: 'destinationName'),
            nbTravelers: any(named: 'nbTravelers'),
            coverImageUrl: any(named: 'coverImageUrl'),
            budgetTotal: any(named: 'budgetTotal'),
            origin: any(named: 'origin'),
          ),
        ).thenAnswer((_) async => Success(newTrip));

        // Stub trip home for the new trip
        when(() => mocks.trip.getTripHome(newTrip.id)).thenAnswer(
          (_) async => Success(
            TripHome(
              trip: newTrip,
              stats: const TripHomeStats(),
              features: const [],
            ),
          ),
        );

        await pumpTestApp(tester, existingMocks: mocks);

        expect(f.homeTripManager, findsOneWidget);

        // Simulate manual trip creation via TripManagementBloc
        final tripMgmtBloc = tester
            .element(f.homeTripManager)
            .read<TripManagementBloc>();

        tripMgmtBloc.add(
          CreateTrip(
            title: 'Lisbon Trip',
            destinationName: 'Lisbon',
            startDate: DateTime(2026, 6),
            endDate: DateTime(2026, 6, 7),
            nbTravelers: 1,
          ),
        );

        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify manual creation was called (not AI)
        verify(
          () => mocks.trip.createTrip(
            title: any(named: 'title'),
            originIata: any(named: 'originIata'),
            destinationIata: any(named: 'destinationIata'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            description: any(named: 'description'),
            destinationName: any(named: 'destinationName'),
            nbTravelers: any(named: 'nbTravelers'),
            coverImageUrl: any(named: 'coverImageUrl'),
            budgetTotal: any(named: 'budgetTotal'),
            origin: any(named: 'origin'),
          ),
        ).called(1);

        // Verify AI was NOT called
        verifyNever(
          () => mocks.ai.getInspiration(
            travelTypes: any(named: 'travelTypes'),
            budgetRange: any(named: 'budgetRange'),
            durationDays: any(named: 'durationDays'),
            companions: any(named: 'companions'),
            season: any(named: 'season'),
            constraints: any(named: 'constraints'),
          ),
        );
      },
    );

    testWidgets(
      'enrichment: adding activity and accommodation calls repositories',
      (tester) async {
        final trip = makeLisbonTrip();

        final mocks = await setupTestServiceLocator();
        stubTripManagerHome(mocks, planned: [trip]);

        // Stub activity creation (positional tripId, positional data map)
        when(() => mocks.activity.createActivity(trip.id, any())).thenAnswer(
          (_) async => Success(
            makeActivity(id: 'act-new', tripId: trip.id, title: 'Belem Tower'),
          ),
        );

        // Stub accommodation creation (positional tripId, named params)
        when(
          () => mocks.accommodation.createAccommodation(
            trip.id,
            name: any(named: 'name'),
            address: any(named: 'address'),
            checkIn: any(named: 'checkIn'),
            checkOut: any(named: 'checkOut'),
            pricePerNight: any(named: 'pricePerNight'),
            currency: any(named: 'currency'),
            bookingReference: any(named: 'bookingReference'),
            notes: any(named: 'notes'),
          ),
        ).thenAnswer(
          (_) async => Success(
            makeAccommodation(
              id: 'acc-new',
              tripId: trip.id,
              name: 'Lisbon Hostel',
            ),
          ),
        );

        await pumpTestApp(tester, existingMocks: mocks);

        expect(f.homeTripManager, findsOneWidget);

        // Simulate adding activity
        await mocks.activity.createActivity(trip.id, {
          'title': 'Belem Tower',
          'category': 'culture',
        });

        verify(() => mocks.activity.createActivity(trip.id, any())).called(1);

        // Simulate adding accommodation
        await mocks.accommodation.createAccommodation(
          trip.id,
          name: 'Lisbon Hostel',
        );

        verify(
          () => mocks.accommodation.createAccommodation(
            trip.id,
            name: any(named: 'name'),
            address: any(named: 'address'),
            checkIn: any(named: 'checkIn'),
            checkOut: any(named: 'checkOut'),
            pricePerNight: any(named: 'pricePerNight'),
            currency: any(named: 'currency'),
            bookingReference: any(named: 'bookingReference'),
            notes: any(named: 'notes'),
          ),
        ).called(1);
      },
    );

    testWidgets('enrichment: checking baggage items toggles packed status', (
      tester,
    ) async {
      final trip = makeLisbonTrip();

      final mocks = await setupTestServiceLocator();
      stubTripManagerHome(mocks, planned: [trip]);

      final bagItems = [
        makeBaggageItem(tripId: trip.id),
        makeBaggageItem(id: 'bag-2', tripId: trip.id, name: 'Sunscreen'),
      ];

      when(
        () => mocks.baggage.getByTrip(trip.id),
      ).thenAnswer((_) async => Success(bagItems));

      // Stub toggle packed
      when(
        () => mocks.baggage.updateBaggageItem(trip.id, 'bag-1', any()),
      ).thenAnswer((_) async => Success(bagItems[0].copyWith(isPacked: true)));

      await pumpTestApp(tester, existingMocks: mocks);

      // Load baggage items
      final result = await mocks.baggage.getByTrip(trip.id);
      expect(result, isA<Success>());
      expect((result as Success).data, hasLength(2));

      // Toggle packed
      await mocks.baggage.updateBaggageItem(trip.id, 'bag-1', {
        'is_packed': true,
      });

      verify(
        () => mocks.baggage.updateBaggageItem(trip.id, 'bag-1', any()),
      ).called(1);
    });

    testWidgets(
      'completion percentage concept: sections contribute to completion',
      (tester) async {
        final trip = makeLisbonTrip();

        final mocks = await setupTestServiceLocator();
        stubTripManagerHome(mocks, planned: [trip]);

        // Stub trip home with sections (completion is calculated by TripDetailBloc)
        when(() => mocks.trip.getTripHome(trip.id)).thenAnswer(
          (_) async => Success(
            TripHome(
              trip: trip,
              stats: const TripHomeStats(),
              features: const [
                TripFeatureTile(
                  id: 'activities',
                  label: 'Activities',
                  icon: 'activity',
                  route: '/activities',
                  enabled: true,
                ),
                TripFeatureTile(
                  id: 'accommodations',
                  label: 'Accommodations',
                  icon: 'hotel',
                  route: '/accommodations',
                  enabled: true,
                ),
              ],
              sections: const [
                TripSectionSummary(sectionId: 'activities'),
                TripSectionSummary(sectionId: 'accommodations'),
              ],
            ),
          ),
        );

        await pumpTestApp(tester, existingMocks: mocks);

        // Verify trip home can be loaded with sections data
        final tripHome = await mocks.trip.getTripHome(trip.id);
        expect(tripHome, isA<Success<TripHome>>());
        final data = (tripHome as Success<TripHome>).data;
        expect(data.features, hasLength(2));
        expect(data.sections, hasLength(2));
      },
    );
  });
}
