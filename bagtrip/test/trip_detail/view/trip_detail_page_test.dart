import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/trip_detail/bloc/trip_detail_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_repositories.dart';
import '../../helpers/test_fixtures.dart';

/// Tests that TripDetailPage's pattern works:
/// BlocProvider creates a TripDetailBloc and fires LoadTripDetail.
/// We verify the bloc receives the event and fetches trip data.
void main() {
  late MockTripRepository mockTripRepo;
  late MockActivityRepository mockActivityRepo;
  late MockAccommodationRepository mockAccommodationRepo;
  late MockBaggageRepository mockBaggageRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockTransportRepository mockTransportRepo;
  late MockTripShareRepository mockTripShareRepo;

  setUp(() {
    mockTripRepo = MockTripRepository();
    mockActivityRepo = MockActivityRepository();
    mockAccommodationRepo = MockAccommodationRepository();
    mockBaggageRepo = MockBaggageRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockTransportRepo = MockTransportRepository();
    mockTripShareRepo = MockTripShareRepository();
  });

  void stubAllSuccess() {
    when(
      () => mockTripRepo.getTripById(any()),
    ).thenAnswer((_) async => Success(makeTrip()));
    when(
      () => mockActivityRepo.getActivities(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockTransportRepo.getManualFlights(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockAccommodationRepo.getByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockBaggageRepo.getByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
    when(
      () => mockBudgetRepo.getBudgetSummary(any()),
    ).thenAnswer((_) async => Success(makeBudgetSummary()));
    when(
      () => mockTripShareRepo.getSharesByTrip(any()),
    ).thenAnswer((_) async => const Success([]));
  }

  group('TripDetailPage bloc creation', () {
    blocTest<TripDetailBloc, TripDetailState>(
      'fires LoadTripDetail and emits Loading then Loaded',
      build: () {
        stubAllSuccess();
        return TripDetailBloc(
          tripRepository: mockTripRepo,
          activityRepository: mockActivityRepo,
          accommodationRepository: mockAccommodationRepo,
          baggageRepository: mockBaggageRepo,
          budgetRepository: mockBudgetRepo,
          transportRepository: mockTransportRepo,
          tripShareRepository: mockTripShareRepo,
        );
      },
      act: (bloc) => bloc.add(LoadTripDetail(tripId: 'trip-1')),
      expect: () => [isA<TripDetailLoading>(), isA<TripDetailLoaded>()],
      verify: (_) {
        verify(() => mockTripRepo.getTripById('trip-1')).called(1);
      },
    );
  });
}
