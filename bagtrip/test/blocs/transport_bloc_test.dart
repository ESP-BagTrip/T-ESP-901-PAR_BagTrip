import 'package:bagtrip/transports/bloc/transport_bloc.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockTransportRepository mockTransportRepo;

  setUp(() {
    mockTransportRepo = MockTransportRepository();
  });

  group('TransportBloc', () {
    // ── Initial state ───────────────────────────────────────────────────

    test('initial state is TransportInitial', () {
      final bloc = TransportBloc(transportRepository: mockTransportRepo);
      expect(bloc.state, isA<TransportInitial>());
      bloc.close();
    });

    // ── LoadTransports ──────────────────────────────────────────────────

    blocTest<TransportBloc, TransportState>(
      'LoadTransports success separates MAIN and INTERNAL flights',
      build: () {
        when(() => mockTransportRepo.getManualFlights(any())).thenAnswer(
          (_) async => Success([
            makeManualFlight(id: 'f1'),
            const ManualFlight(
              id: 'f2',
              tripId: 'trip-1',
              flightNumber: 'IB456',
              flightType: 'INTERNAL',
            ),
          ]),
        );
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(LoadTransports(tripId: 'trip-1')),
      expect: () => [isA<TransportLoading>(), isA<TransportsLoaded>()],
      verify: (bloc) {
        final state = bloc.state as TransportsLoaded;
        expect(state.transports.length, 2);
        expect(state.mainFlights.length, 1);
        expect(state.mainFlights.first.id, 'f1');
        expect(state.internalFlights.length, 1);
        expect(state.internalFlights.first.id, 'f2');
      },
    );

    blocTest<TransportBloc, TransportState>(
      'LoadTransports failure emits TransportError',
      build: () {
        when(() => mockTransportRepo.getManualFlights(any())).thenAnswer(
          (_) async => const Failure(NetworkError('Connection lost')),
        );
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(LoadTransports(tripId: 'trip-1')),
      expect: () => [isA<TransportLoading>(), isA<TransportError>()],
    );

    // ── CreateManualFlight ──────────────────────────────────────────────

    blocTest<TransportBloc, TransportState>(
      'CreateManualFlight success triggers LoadTransports',
      build: () {
        when(
          () => mockTransportRepo.createManualFlight(any(), any()),
        ).thenAnswer((_) async => Success(makeManualFlight()));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => Success([makeManualFlight()]));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(
        CreateManualFlight(tripId: 'trip-1', data: {'flightNumber': 'AF123'}),
      ),
      expect: () => [
        // LoadTransports triggered internally
        isA<TransportLoading>(),
        isA<TransportsLoaded>(),
      ],
      verify: (_) {
        verify(
          () => mockTransportRepo.createManualFlight('trip-1', {
            'flightNumber': 'AF123',
          }),
        ).called(1);
        verify(() => mockTransportRepo.getManualFlights('trip-1')).called(1);
      },
    );

    blocTest<TransportBloc, TransportState>(
      'CreateManualFlight failure emits TransportError',
      build: () {
        when(
          () => mockTransportRepo.createManualFlight(any(), any()),
        ).thenAnswer((_) async => const Failure(ServerError('Create failed')));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(
        CreateManualFlight(tripId: 'trip-1', data: {'flightNumber': 'AF123'}),
      ),
      expect: () => [isA<TransportError>()],
    );

    // ── DeleteManualFlight ──────────────────────────────────────────────

    blocTest<TransportBloc, TransportState>(
      'DeleteManualFlight success triggers LoadTransports',
      build: () {
        when(
          () => mockTransportRepo.deleteManualFlight(any(), any()),
        ).thenAnswer((_) async => const Success(null));
        when(
          () => mockTransportRepo.getManualFlights(any()),
        ).thenAnswer((_) async => const Success(<ManualFlight>[]));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteManualFlight(tripId: 'trip-1', flightId: 'flight-1')),
      expect: () => [isA<TransportLoading>(), isA<TransportsLoaded>()],
      verify: (_) {
        verify(
          () => mockTransportRepo.deleteManualFlight('trip-1', 'flight-1'),
        ).called(1);
      },
    );

    blocTest<TransportBloc, TransportState>(
      'DeleteManualFlight failure emits TransportError',
      build: () {
        when(
          () => mockTransportRepo.deleteManualFlight(any(), any()),
        ).thenAnswer((_) async => const Failure(NotFoundError('Not found')));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) =>
          bloc.add(DeleteManualFlight(tripId: 'trip-1', flightId: 'flight-1')),
      expect: () => [isA<TransportError>()],
    );

    // ── LookupFlightInfo ────────────────────────────────────────────────

    blocTest<TransportBloc, TransportState>(
      'LookupFlightInfo success emits FlightLookupLoading then FlightLookupLoaded',
      build: () {
        when(
          () => mockTransportRepo.lookupFlight(any()),
        ).thenAnswer((_) async => Success(makeFlightInfo()));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(LookupFlightInfo(flightNumber: 'AF123')),
      expect: () => [isA<FlightLookupLoading>(), isA<FlightLookupLoaded>()],
      verify: (bloc) {
        final state = bloc.state as FlightLookupLoaded;
        expect(state.info.flightIata, 'AF123');
      },
    );

    blocTest<TransportBloc, TransportState>(
      'LookupFlightInfo failure emits FlightLookupLoading then FlightLookupError',
      build: () {
        when(
          () => mockTransportRepo.lookupFlight(any()),
        ).thenAnswer((_) async => const Failure(NetworkError('Lookup failed')));
        return TransportBloc(transportRepository: mockTransportRepo);
      },
      act: (bloc) => bloc.add(LookupFlightInfo(flightNumber: 'XX999')),
      expect: () => [isA<FlightLookupLoading>(), isA<FlightLookupError>()],
    );

    // ── ClearFlightLookup ───────────────────────────────────────────────

    blocTest<TransportBloc, TransportState>(
      'ClearFlightLookup emits TransportInitial',
      build: () => TransportBloc(transportRepository: mockTransportRepo),
      seed: () => FlightLookupLoaded(info: makeFlightInfo()),
      act: (bloc) => bloc.add(ClearFlightLookup()),
      expect: () => [isA<TransportInitial>()],
    );
  });
}
