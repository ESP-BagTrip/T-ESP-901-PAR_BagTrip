import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  group('LocationService Result types', () {
    late LocationService locationService;
    late Dio dio;
    late DioAdapter dioAdapter;

    setUp(() {
      dio = Dio();
      dioAdapter = DioAdapter(dio: dio);
      locationService = LocationService(dio: dio);
    });

    tearDown(() {
      dio.close();
    });

    final flightQueryParams = {
      'originLocationCode': 'CDG',
      'destinationLocationCode': 'JFK',
      'departureDate': '2024-06-15',
      'adults': 1,
      'children': 0,
      'infants': 0,
      'travelClass': 'ECONOMY',
      'currencyCode': 'EUR',
    };

    group('searchFlights', () {
      test('success path returns Result.success with flights', () async {
        final mockFlight = {
          'id': 'flight-ok',
          'itineraries': [
            {
              'duration': 'PT8H00M',
              'segments': [
                {
                  'departure': {
                    'at': '2024-06-15T10:00:00',
                    'iataCode': 'CDG',
                    'terminal': '2E',
                  },
                  'arrival': {
                    'at': '2024-06-15T14:00:00',
                    'iataCode': 'JFK',
                    'terminal': '1',
                  },
                },
              ],
            },
          ],
          'price': {'grandTotal': '650.00', 'base': '580.00'},
          'numberOfBookableSeats': 4,
          'lastTicketingDate': '2024-06-10',
          'validatingAirlineCodes': ['AF'],
          'travelerPricings': [
            {
              'fareDetailsBySegment': [
                {'cabin': 'ECONOMY', 'class': 'Y', 'fareBasis': 'Y26'},
              ],
            },
          ],
        };

        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.reply(200, [mockFlight]),
          queryParameters: flightQueryParams,
        );

        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-06-15',
          adults: 1,
        );

        expect(result, isA<Success<List<Flight>>>());
        final flights = (result as Success<List<Flight>>).data;
        expect(flights, isNotEmpty);
        expect(flights.first.id, 'flight-ok');
      });

      test('DioException maps to Result.failure with NetworkError', () async {
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: '/test'),
              error: 'Connection refused',
              type: DioExceptionType.connectionError,
            ),
          ),
          queryParameters: flightQueryParams,
        );

        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-06-15',
          adults: 1,
        );

        expect(result, isA<Failure<List<Flight>>>());
        final failure = result as Failure<List<Flight>>;
        expect(failure.error, isA<NetworkError>());
        expect(failure.error.message, contains('Error searching flights'));
      });

      test('non-200 status maps to Result.failure with ServerError', () async {
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.reply(500, {'error': 'Internal server error'}),
          queryParameters: flightQueryParams,
        );

        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-06-15',
          adults: 1,
        );

        expect(result, isA<Failure<List<Flight>>>());
      });
    });

    group('searchLocationsByKeyword', () {
      test('success path returns Result.success with locations', () async {
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, [
            {
              'iataCode': 'CDG',
              'name': 'Charles de Gaulle',
              'address': {
                'cityName': 'Paris',
                'countryCode': 'FR',
                'countryName': 'France',
              },
            },
          ]),
          queryParameters: {'keyword': 'Paris', 'subType': 'AIRPORT'},
        );

        final result = await locationService.searchLocationsByKeyword(
          'Paris',
          'AIRPORT',
        );

        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final locations = (result as Success<List<Map<String, dynamic>>>).data;
        expect(locations.length, 1);
        expect(locations.first['iataCode'], 'CDG');
      });

      test('network error returns Result.failure with NetworkError', () async {
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: '/test'),
              error: 'Socket timeout',
            ),
          ),
          queryParameters: {'keyword': 'Nowhere', 'subType': 'AIRPORT'},
        );

        final result = await locationService.searchLocationsByKeyword(
          'Nowhere',
          'AIRPORT',
        );

        expect(result, isA<Failure<List<Map<String, dynamic>>>>());
        final failure = result as Failure<List<Map<String, dynamic>>>;
        expect(failure.error, isA<NetworkError>());
      });

      test(
        'unexpected empty response returns Result.failure with ServerError',
        () async {
          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(200, {}),
            queryParameters: {'keyword': 'Empty', 'subType': 'AIRPORT'},
          );

          final result = await locationService.searchLocationsByKeyword(
            'Empty',
            'AIRPORT',
          );

          expect(result, isA<Failure<List<Map<String, dynamic>>>>());
          final failure = result as Failure<List<Map<String, dynamic>>>;
          expect(failure.error, isA<ServerError>());
        },
      );
    });
  });
}
