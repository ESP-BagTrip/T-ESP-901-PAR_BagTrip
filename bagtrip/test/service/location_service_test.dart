import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:bagtrip/service/location_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  group('LocationService', () {
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

    group('searchFlights', () {
      test(
        'should return list of flights when API returns list response',
        () async {
          // Arrange
          final mockFlightData = {
            'id': 'flight-1',
            'itineraries': [
              {
                'duration': 'PT2H30M',
                'segments': [
                  {
                    'departure': {
                      'at': '2024-01-15T10:00:00',
                      'iataCode': 'CDG',
                      'terminal': '2',
                    },
                    'arrival': {
                      'at': '2024-01-15T12:30:00',
                      'iataCode': 'JFK',
                      'terminal': '4',
                    },
                    'aircraft': {'code': '320'},
                  },
                ],
              },
            ],
            'price': {'grandTotal': '500.00', 'base': '450.00'},
            'numberOfBookableSeats': 9,
            'lastTicketingDate': '2024-01-10',
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
            (server) => server.reply(200, [mockFlightData]),
            queryParameters: {
              'originLocationCode': 'CDG',
              'destinationLocationCode': 'JFK',
              'departureDate': '2024-01-15',
              'adults': 1,
              'children': 0,
              'infants': 0,
              'travelClass': 'ECONOMY',
              'currencyCode': 'EUR',
            },
          );

          // Act
          final result = await locationService.searchFlights(
            departureCode: 'CDG',
            arrivalCode: 'JFK',
            departureDate: '2024-01-15',
            adults: 1,
          );

          // Assert
          expect(result, isA<Success<List<Flight>>>());
          final flights = (result as Success<List<Flight>>).data;
          expect(flights.length, equals(1));
          expect(flights.first.id, equals('flight-1'));
          expect(flights.first.departureCode, contains('CDG'));
          expect(flights.first.arrivalCode, contains('JFK'));
          expect(flights.first.price, equals(500.0));
        },
      );

      test(
        'should return list of flights when API returns map with data key',
        () async {
          // Arrange
          final mockFlightData = {
            'id': 'flight-2',
            'itineraries': [
              {
                'duration': 'PT3H15M',
                'segments': [
                  {
                    'departure': {
                      'at': '2024-01-20T14:00:00',
                      'iataCode': 'LHR',
                    },
                    'arrival': {'at': '2024-01-20T17:15:00', 'iataCode': 'LAX'},
                  },
                ],
              },
            ],
            'price': {'grandTotal': '800.00', 'base': '750.00'},
            'numberOfBookableSeats': 5,
            'lastTicketingDate': '2024-01-18',
            'validatingAirlineCodes': ['BA'],
            'travelerPricings': [
              {
                'fareDetailsBySegment': [
                  {'cabin': 'BUSINESS', 'class': 'J', 'fareBasis': 'J12'},
                ],
              },
            ],
          };

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/flight/offers',
            (server) => server.reply(200, {
              'data': [mockFlightData],
            }),
            queryParameters: {
              'originLocationCode': 'LHR',
              'destinationLocationCode': 'LAX',
              'departureDate': '2024-01-20',
              'adults': 2,
              'children': 1,
              'infants': 0,
              'travelClass': 'BUSINESS',
              'currencyCode': 'EUR',
            },
          );

          // Act
          final result = await locationService.searchFlights(
            departureCode: 'LHR',
            arrivalCode: 'LAX',
            departureDate: '2024-01-20',
            adults: 2,
            children: 1,
            travelClass: 'BUSINESS',
          );

          // Assert
          expect(result, isA<Success<List<Flight>>>());
          final flights = (result as Success<List<Flight>>).data;
          expect(flights.length, equals(1));
          expect(flights.first.id, equals('flight-2'));
          expect(flights.first.price, equals(800.0));
        },
      );

      test(
        'should include returnDate in query parameters when provided',
        () async {
          // Arrange
          final mockFlightData = {
            'id': 'flight-3',
            'itineraries': [
              {
                'duration': 'PT2H00M',
                'segments': [
                  {
                    'departure': {
                      'at': '2024-02-01T08:00:00',
                      'iataCode': 'CDG',
                    },
                    'arrival': {'at': '2024-02-01T10:00:00', 'iataCode': 'LHR'},
                  },
                ],
              },
              {
                'duration': 'PT2H15M',
                'segments': [
                  {
                    'departure': {
                      'at': '2024-02-10T12:00:00',
                      'iataCode': 'LHR',
                    },
                    'arrival': {'at': '2024-02-10T14:15:00', 'iataCode': 'CDG'},
                  },
                ],
              },
            ],
            'price': {'grandTotal': '600.00', 'base': '550.00'},
            'numberOfBookableSeats': 7,
            'lastTicketingDate': '2024-01-28',
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
            (server) => server.reply(200, [mockFlightData]),
            queryParameters: {
              'originLocationCode': 'CDG',
              'destinationLocationCode': 'LHR',
              'departureDate': '2024-02-01',
              'returnDate': '2024-02-10',
              'adults': 1,
              'children': 0,
              'infants': 0,
              'travelClass': 'ECONOMY',
              'currencyCode': 'EUR',
            },
          );

          // Act
          final result = await locationService.searchFlights(
            departureCode: 'CDG',
            arrivalCode: 'LHR',
            departureDate: '2024-02-01',
            returnDate: '2024-02-10',
            adults: 1,
          );

          // Assert
          expect(result, isA<Success<List<Flight>>>());
          final flights = (result as Success<List<Flight>>).data;
          expect(flights.length, equals(1));
          expect(flights.first.returnDepartureTime, isNotNull);
          expect(flights.first.returnArrivalTime, isNotNull);
        },
      );

      test('should handle dictionaries in response', () async {
        // Arrange
        final mockFlightData = {
          'id': 'flight-4',
          'itineraries': [
            {
              'duration': 'PT4H00M',
              'segments': [
                {
                  'departure': {'at': '2024-03-01T09:00:00', 'iataCode': 'JFK'},
                  'arrival': {'at': '2024-03-01T13:00:00', 'iataCode': 'LAX'},
                  'aircraft': {'code': '777'},
                },
              ],
            },
          ],
          'price': {'grandTotal': '900.00', 'base': '850.00'},
          'numberOfBookableSeats': 3,
          'lastTicketingDate': '2024-02-25',
          'validatingAirlineCodes': ['AA'],
          'travelerPricings': [
            {
              'fareDetailsBySegment': [
                {'cabin': 'ECONOMY', 'class': 'Y', 'fareBasis': 'Y26'},
              ],
            },
          ],
        };

        final mockDictionaries = {
          'carriers': {'AA': 'American Airlines'},
          'aircraft': {'777': 'Boeing 777'},
        };

        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.reply(200, {
            'data': [mockFlightData],
            'dictionaries': mockDictionaries,
          }),
          queryParameters: {
            'originLocationCode': 'JFK',
            'destinationLocationCode': 'LAX',
            'departureDate': '2024-03-01',
            'adults': 1,
            'children': 0,
            'infants': 0,
            'travelClass': 'ECONOMY',
            'currencyCode': 'EUR',
          },
        );

        // Act
        final result = await locationService.searchFlights(
          departureCode: 'JFK',
          arrivalCode: 'LAX',
          departureDate: '2024-03-01',
          adults: 1,
        );

        // Assert
        expect(result, isA<Success<List<Flight>>>());
        final flights = (result as Success<List<Flight>>).data;
        expect(flights.length, equals(1));
        // The airline name should be extracted from dictionaries if available
      });

      test('should throw exception when HTTP status is not 200', () async {
        // Arrange
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.reply(404, {'error': 'Not found'}),
          queryParameters: {
            'originLocationCode': 'CDG',
            'destinationLocationCode': 'JFK',
            'departureDate': '2024-01-15',
            'adults': 1,
            'children': 0,
            'infants': 0,
            'travelClass': 'ECONOMY',
            'currencyCode': 'EUR',
          },
        );

        // Act & Assert
        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-01-15',
          adults: 1,
        );
        expect(result, isA<Failure<List<Flight>>>());
      });

      test('should throw exception on network error', () async {
        // Arrange
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/flight/offers',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/test'),
              error: 'Network error',
            ),
          ),
          queryParameters: {
            'originLocationCode': 'CDG',
            'destinationLocationCode': 'JFK',
            'departureDate': '2024-01-15',
            'adults': 1,
            'children': 0,
            'infants': 0,
            'travelClass': 'ECONOMY',
            'currencyCode': 'EUR',
          },
        );

        // Act & Assert
        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-01-15',
          adults: 1,
        );
        expect(result, isA<Failure<List<Flight>>>());
      });

      test('should handle multi-destination segments parameter', () async {
        // Arrange
        final mockFlightData = {
          'id': 'flight-5',
          'itineraries': [
            {
              'duration': 'PT2H30M',
              'segments': [
                {
                  'departure': {'at': '2024-04-01T10:00:00', 'iataCode': 'CDG'},
                  'arrival': {'at': '2024-04-01T12:30:00', 'iataCode': 'JFK'},
                },
              ],
            },
          ],
          'price': {'grandTotal': '500.00', 'base': '450.00'},
          'numberOfBookableSeats': 9,
          'lastTicketingDate': '2024-03-28',
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
          (server) => server.reply(200, [mockFlightData]),
          queryParameters: {
            'originLocationCode': 'CDG',
            'destinationLocationCode': 'JFK',
            'departureDate': '2024-04-01',
            'adults': 1,
            'children': 0,
            'infants': 0,
            'travelClass': 'ECONOMY',
            'currencyCode': 'EUR',
          },
        );

        // Act
        final result = await locationService.searchFlights(
          departureCode: 'CDG',
          arrivalCode: 'JFK',
          departureDate: '2024-04-01',
          adults: 1,
          multiDestSegments: [
            const FlightSegment(
              departureAirport: {'code': 'CDG'},
              arrivalAirport: {'code': 'JFK'},
            ),
          ],
        );

        // Assert
        expect(result, isA<Success<List<Flight>>>());
        // Multi-destination is not yet implemented, but should not throw
      });
    });

    group('searchLocationsByKeyword', () {
      test('should return locations when API returns list response', () async {
        // Arrange
        final mockLocationData = [
          {
            'iataCode': 'CDG',
            'name': 'Charles de Gaulle Airport',
            'address': {
              'cityName': 'Paris',
              'countryCode': 'FR',
              'countryName': 'France',
            },
          },
          {
            'iataCode': 'ORY',
            'name': 'Orly Airport',
            'address': {
              'cityName': 'Paris',
              'countryCode': 'FR',
              'countryName': 'France',
            },
          },
        ];

        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, mockLocationData),
          queryParameters: {'keyword': 'Paris', 'subType': 'AIRPORT'},
        );

        // Act
        final result = await locationService.searchLocationsByKeyword(
          'Paris',
          'AIRPORT',
        );

        // Assert
        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final locations = (result as Success<List<Map<String, dynamic>>>).data;
        expect(locations.length, equals(2));
        expect(locations[0]['iataCode'], equals('CDG'));
        expect(locations[0]['city'], equals('Paris'));
        expect(locations[0]['countryCode'], equals('FR'));
        expect(locations[0]['countryName'], equals('France'));
      });

      test(
        'should return locations when API returns map with locations key',
        () async {
          // Arrange
          final mockLocationData = {
            'locations': [
              {
                'iataCode': 'JFK',
                'name': 'John F. Kennedy International Airport',
                'address': {
                  'cityName': 'New York',
                  'countryCode': 'US',
                  'countryName': 'United States',
                },
              },
            ],
            'count': 1,
          };

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(200, mockLocationData),
            queryParameters: {'keyword': 'New York', 'subType': 'AIRPORT'},
          );

          // Act
          final result = await locationService.searchLocationsByKeyword(
            'New York',
            'AIRPORT',
          );

          // Assert
          expect(result, isA<Success<List<Map<String, dynamic>>>>());
          final locations =
              (result as Success<List<Map<String, dynamic>>>).data;
          expect(locations.length, equals(1));
          expect(locations[0]['iataCode'], equals('JFK'));
          expect(locations[0]['city'], equals('New York'));
          expect(locations[0]['countryCode'], equals('US'));
        },
      );

      test(
        'should return locations when API returns map with data key',
        () async {
          // Arrange
          final mockLocationData = {
            'data': [
              {
                'iataCode': 'LHR',
                'name': 'London Heathrow Airport',
                'address': {
                  'cityName': 'London',
                  'countryCode': 'GB',
                  'countryName': 'United Kingdom',
                },
              },
            ],
          };

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(200, mockLocationData),
            queryParameters: {'keyword': 'London', 'subType': 'AIRPORT'},
          );

          // Act
          final result = await locationService.searchLocationsByKeyword(
            'London',
            'AIRPORT',
          );

          // Assert
          expect(result, isA<Success<List<Map<String, dynamic>>>>());
          final locations =
              (result as Success<List<Map<String, dynamic>>>).data;
          expect(locations.length, equals(1));
          expect(locations[0]['iataCode'], equals('LHR'));
          expect(locations[0]['city'], equals('London'));
        },
      );

      test(
        'should return single location when API returns single object',
        () async {
          // Arrange
          final mockLocationData = {
            'iataCode': 'LAX',
            'name': 'Los Angeles International Airport',
            'address': {
              'cityName': 'Los Angeles',
              'countryCode': 'US',
              'countryName': 'United States',
            },
          };

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(200, mockLocationData),
            queryParameters: {'keyword': 'Los Angeles', 'subType': 'AIRPORT'},
          );

          // Act
          final result = await locationService.searchLocationsByKeyword(
            'Los Angeles',
            'AIRPORT',
          );

          // Assert
          expect(result, isA<Success<List<Map<String, dynamic>>>>());
          final locations =
              (result as Success<List<Map<String, dynamic>>>).data;
          expect(locations.length, equals(1));
          expect(locations[0]['iataCode'], equals('LAX'));
          expect(locations[0]['city'], equals('Los Angeles'));
        },
      );

      test(
        'should return locations even when HTTP status is error but data is valid',
        () async {
          // Arrange
          final mockLocationData = [
            {
              'iataCode': 'CDG',
              'name': 'Charles de Gaulle Airport',
              'address': {
                'cityName': 'Paris',
                'countryCode': 'FR',
                'countryName': 'France',
              },
            },
          ];

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(400, mockLocationData),
            queryParameters: {'keyword': 'Paris', 'subType': 'AIRPORT'},
          );

          // Act
          final result = await locationService.searchLocationsByKeyword(
            'Paris',
            'AIRPORT',
          );

          // Assert
          expect(result, isA<Success<List<Map<String, dynamic>>>>());
          final locations =
              (result as Success<List<Map<String, dynamic>>>).data;
          expect(locations.length, equals(1));
          expect(locations[0]['iataCode'], equals('CDG'));
        },
      );

      test(
        'should return locations from DioException response data if valid',
        () async {
          // Arrange
          final mockLocationData = {
            'locations': [
              {
                'iataCode': 'FCO',
                'name': 'Leonardo da Vinci Airport',
                'address': {
                  'cityName': 'Rome',
                  'countryCode': 'IT',
                  'countryName': 'Italy',
                },
              },
            ],
          };

          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(500, mockLocationData),
            queryParameters: {'keyword': 'Rome', 'subType': 'AIRPORT'},
          );

          // Act
          final result = await locationService.searchLocationsByKeyword(
            'Rome',
            'AIRPORT',
          );

          // Assert
          expect(result, isA<Success<List<Map<String, dynamic>>>>());
          final locations =
              (result as Success<List<Map<String, dynamic>>>).data;
          expect(locations.length, equals(1));
          expect(locations[0]['iataCode'], equals('FCO'));
          expect(locations[0]['city'], equals('Rome'));
        },
      );

      test('empty map response returns Success with empty list', () async {
        // Arrange
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, {}),
          queryParameters: {'keyword': 'Test', 'subType': 'AIRPORT'},
        );

        // Act & Assert
        final result = await locationService.searchLocationsByKeyword(
          'Test',
          'AIRPORT',
        );
        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final success = result as Success<List<Map<String, dynamic>>>;
        expect(success.data, isEmpty);
      });

      test(
        'should throw exception when HTTP error and no valid data',
        () async {
          // Arrange
          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.reply(404, {'error': 'Not found'}),
            queryParameters: {'keyword': 'Invalid', 'subType': 'AIRPORT'},
          );

          // Act & Assert
          final result = await locationService.searchLocationsByKeyword(
            'Invalid',
            'AIRPORT',
          );
          expect(result, isA<Failure<List<Map<String, dynamic>>>>());
        },
      );

      test(
        'should throw exception on network error with no response data',
        () async {
          // Arrange
          dioAdapter.onGet(
            'http://localhost:3000/v1/travel/locations',
            (server) => server.throws(
              0,
              DioException(
                requestOptions: RequestOptions(path: '/test'),
                error: 'Network error',
              ),
            ),
            queryParameters: {'keyword': 'Test', 'subType': 'AIRPORT'},
          );

          // Act & Assert
          final result = await locationService.searchLocationsByKeyword(
            'Test',
            'AIRPORT',
          );
          expect(result, isA<Failure<List<Map<String, dynamic>>>>());
        },
      );

      test('should handle location without address field', () async {
        // Arrange
        final mockLocationData = [
          {
            'iataCode': 'TEST',
            'name': 'Test Airport',
            // No address field
          },
        ];

        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, mockLocationData),
          queryParameters: {'keyword': 'Test', 'subType': 'AIRPORT'},
        );

        // Act
        final result = await locationService.searchLocationsByKeyword(
          'Test',
          'AIRPORT',
        );

        // Assert
        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final locations = (result as Success<List<Map<String, dynamic>>>).data;
        expect(locations.length, equals(1));
        expect(locations[0]['iataCode'], equals('TEST'));
        // Should not have city, countryCode, countryName if no address
      });

      test('should handle empty response list', () async {
        // Arrange
        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, []),
          queryParameters: {'keyword': 'NonExistent', 'subType': 'AIRPORT'},
        );

        // Act & Assert
        final result = await locationService.searchLocationsByKeyword(
          'NonExistent',
          'AIRPORT',
        );
        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final success = result as Success<List<Map<String, dynamic>>>;
        expect(success.data, isEmpty);
      });
    });

    group('_flattenLocation (indirect testing)', () {
      test('should flatten location with address correctly', () async {
        // Arrange
        final mockLocationData = [
          {
            'iataCode': 'CDG',
            'name': 'Charles de Gaulle Airport',
            'address': {
              'cityName': 'Paris',
              'countryCode': 'FR',
              'countryName': 'France',
            },
          },
        ];

        dioAdapter.onGet(
          'http://localhost:3000/v1/travel/locations',
          (server) => server.reply(200, mockLocationData),
          queryParameters: {'keyword': 'Paris', 'subType': 'AIRPORT'},
        );

        // Act
        final result = await locationService.searchLocationsByKeyword(
          'Paris',
          'AIRPORT',
        );

        // Assert
        expect(result, isA<Success<List<Map<String, dynamic>>>>());
        final locations = (result as Success<List<Map<String, dynamic>>>).data;
        expect(locations[0], containsPair('city', 'Paris'));
        expect(locations[0], containsPair('countryCode', 'FR'));
        expect(locations[0], containsPair('countryName', 'France'));
        expect(locations[0], containsPair('iataCode', 'CDG'));
      });
    });
  });
}
