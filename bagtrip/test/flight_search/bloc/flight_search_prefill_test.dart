import 'package:bagtrip/flight_search/bloc/flight_search_bloc.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockLocationService mockLocationService;

  setUp(() {
    mockLocationService = MockLocationService();
  });

  FlightSearchBloc buildBloc() =>
      FlightSearchBloc(locationService: mockLocationService);

  group('InitWithPrefilledData', () {
    blocTest<FlightSearchBloc, FlightSearchState>(
      'sets both departure and arrival airports',
      build: buildBloc,
      act: (bloc) => bloc.add(
        InitWithPrefilledData(
          departureAirport: {'iataCode': 'CDG', 'name': 'CDG'},
          arrivalAirport: {'iataCode': 'NRT', 'name': 'NRT'},
        ),
      ),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having(
              (s) => s.departureAirport?['iataCode'],
              'departureAirport.iataCode',
              'CDG',
            )
            .having(
              (s) => s.arrivalAirport?['iataCode'],
              'arrivalAirport.iataCode',
              'NRT',
            ),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'sets dates and adults from prefill',
      build: buildBloc,
      act: (bloc) => bloc.add(
        InitWithPrefilledData(
          departureDate: DateTime(2024, 8, 15),
          returnDate: DateTime(2024, 8, 22),
          adults: 3,
        ),
      ),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having(
              (s) => s.departureDate,
              'departureDate',
              DateTime(2024, 8, 15),
            )
            .having((s) => s.returnDate, 'returnDate', DateTime(2024, 8, 22))
            .having((s) => s.adults, 'adults', 3),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'null fields default gracefully without crash',
      build: buildBloc,
      act: (bloc) => bloc.add(InitWithPrefilledData()),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having((s) => s.departureAirport, 'departureAirport', isNull)
            .having((s) => s.arrivalAirport, 'arrivalAirport', isNull)
            .having((s) => s.departureDate, 'departureDate', isNull)
            .having((s) => s.returnDate, 'returnDate', isNull)
            .having((s) => s.adults, 'adults', 1),
      ],
    );

    blocTest<FlightSearchBloc, FlightSearchState>(
      'sets only departure airport when arrival is null',
      build: buildBloc,
      act: (bloc) => bloc.add(
        InitWithPrefilledData(
          departureAirport: {'iataCode': 'CDG', 'name': 'CDG'},
        ),
      ),
      expect: () => [
        isA<FlightSearchLoaded>()
            .having(
              (s) => s.departureAirport?['iataCode'],
              'departureAirport.iataCode',
              'CDG',
            )
            .having((s) => s.arrivalAirport, 'arrivalAirport', isNull),
      ],
    );
  });
}
