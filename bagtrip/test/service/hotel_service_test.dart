import 'package:bagtrip/service/hotel_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  group('HotelService', () {
    late HotelService hotelService;
    late Dio dio;
    late DioAdapter dioAdapter;

    setUp(() {
      dio = Dio();
      dioAdapter = DioAdapter(dio: dio);
      hotelService = HotelService(dio: dio);
    });

    tearDown(() {
      dio.close();
    });

    group('searchHotelsByLocation', () {
      test('should return list of hotels when API returns list response', () async {
        final mockHotelData = [
          {
            'hotelId': 'hotel-1',
            'name': 'Grand Hotel Paris',
            'geoCode': {'latitude': 48.8566, 'longitude': 2.3522},
            'rating': 4.5,
            'address': {
              'lines': ['123 Rue de Rivoli'],
              'cityName': 'Paris',
              'countryCode': 'FR',
            },
            'offers': [
              {
                'price': {'total': '150.00', 'currency': 'EUR'},
              },
            ],
            'amenities': ['WIFI', 'POOL', 'SPA'],
          },
        ];

        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(200, mockHotelData),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 48.8566,
          longitude: 2.3522,
          checkIn: '2024-01-15',
          checkOut: '2024-01-17',
        );

        expect(result, isA<List<Hotel>>());
        expect(result.length, 1);
        expect(result.first.id, 'hotel-1');
        expect(result.first.name, 'Grand Hotel Paris');
        expect(result.first.latitude, 48.8566);
        expect(result.first.longitude, 2.3522);
        expect(result.first.pricePerNight, 150.0);
        expect(result.first.rating, 4.5);
        expect(result.first.amenities, contains('WIFI'));
      });

      test('should return list of hotels when API returns data key', () async {
        final mockResponse = {
          'data': [
            {
              'hotelId': 'hotel-2',
              'name': 'Hotel London',
              'geoCode': {'latitude': 51.5074, 'longitude': -0.1278},
              'offers': [
                {
                  'price': {'total': '200.00', 'currency': 'GBP'},
                },
              ],
            },
          ],
        };

        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(200, mockResponse),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 51.5074,
          longitude: -0.1278,
          checkIn: '2024-02-01',
          checkOut: '2024-02-03',
          adults: 2,
        );

        expect(result, isA<List<Hotel>>());
        expect(result.length, 1);
        expect(result.first.id, 'hotel-2');
        expect(result.first.pricePerNight, 200.0);
        expect(result.first.currency, 'GBP');
      });

      test('should return list of hotels when API returns hotels key', () async {
        final mockResponse = {
          'hotels': [
            {
              'id': 'hotel-3',
              'name': 'Berlin Hotel',
              'latitude': 52.5200,
              'longitude': 13.4050,
              'pricePerNight': 120.0,
              'currency': 'EUR',
            },
          ],
        };

        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(200, mockResponse),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 52.5200,
          longitude: 13.4050,
          checkIn: '2024-03-01',
          checkOut: '2024-03-05',
        );

        expect(result, isA<List<Hotel>>());
        expect(result.length, 1);
        expect(result.first.id, 'hotel-3');
        expect(result.first.name, 'Berlin Hotel');
      });

      test('should return empty list when no hotels found', () async {
        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(200, {'hotels': []}),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 0.0,
          longitude: 0.0,
          checkIn: '2024-01-01',
          checkOut: '2024-01-02',
        );

        expect(result, isA<List<Hotel>>());
        expect(result.isEmpty, true);
      });

      test('should filter out hotels without coordinates', () async {
        final mockHotelData = [
          {
            'hotelId': 'hotel-valid',
            'name': 'Valid Hotel',
            'geoCode': {'latitude': 48.8566, 'longitude': 2.3522},
          },
          {
            'hotelId': 'hotel-invalid',
            'name': 'Invalid Hotel',
            // No geoCode
          },
        ];

        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(200, mockHotelData),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 48.8566,
          longitude: 2.3522,
          checkIn: '2024-01-15',
          checkOut: '2024-01-17',
        );

        expect(result.length, 1);
        expect(result.first.id, 'hotel-valid');
      });

      test('should throw exception on network error', () async {
        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/test'),
              error: 'Network error',
            ),
          ),
          data: Matchers.any,
        );

        expect(
          () => hotelService.searchHotelsByLocation(
            latitude: 48.8566,
            longitude: 2.3522,
            checkIn: '2024-01-15',
            checkOut: '2024-01-17',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should return hotels from DioException response if valid', () async {
        final mockHotelData = [
          {
            'hotelId': 'hotel-error',
            'name': 'Error Hotel',
            'geoCode': {'latitude': 48.8566, 'longitude': 2.3522},
          },
        ];

        dioAdapter.onPost(
          'http://localhost:3000/v1/trips/default/hotels/searches',
          (server) => server.reply(400, mockHotelData),
          data: Matchers.any,
        );

        final result = await hotelService.searchHotelsByLocation(
          latitude: 48.8566,
          longitude: 2.3522,
          checkIn: '2024-01-15',
          checkOut: '2024-01-17',
        );

        expect(result.length, 1);
        expect(result.first.id, 'hotel-error');
      });
    });

    group('getHotelDetails', () {
      test('should return hotel details when API returns direct object', () async {
        final mockHotelData = {
          'hotelId': 'hotel-detail',
          'name': 'Detailed Hotel',
          'geoCode': {'latitude': 48.8566, 'longitude': 2.3522},
          'rating': 4.8,
        };

        dioAdapter.onGet(
          'http://localhost:3000/v1/hotels/hotel-detail',
          (server) => server.reply(200, mockHotelData),
        );

        final result = await hotelService.getHotelDetails('hotel-detail');

        expect(result, isA<Hotel>());
        expect(result!.id, 'hotel-detail');
        expect(result.name, 'Detailed Hotel');
        expect(result.rating, 4.8);
      });

      test('should return hotel details when API returns nested object', () async {
        final mockResponse = {
          'hotel': {
            'hotelId': 'hotel-nested',
            'name': 'Nested Hotel',
            'geoCode': {'latitude': 51.5074, 'longitude': -0.1278},
          },
        };

        dioAdapter.onGet(
          'http://localhost:3000/v1/hotels/hotel-nested',
          (server) => server.reply(200, mockResponse),
        );

        final result = await hotelService.getHotelDetails('hotel-nested');

        expect(result, isA<Hotel>());
        expect(result!.id, 'hotel-nested');
        expect(result.name, 'Nested Hotel');
      });

      test('should throw exception when API fails', () async {
        dioAdapter.onGet(
          'http://localhost:3000/v1/hotels/invalid-id',
          (server) => server.reply(404, {'error': 'Not found'}),
        );

        expect(
          () => hotelService.getHotelDetails('invalid-id'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });

  group('Hotel', () {
    test('should parse from JSON with geoCode', () {
      final json = {
        'hotelId': 'test-hotel',
        'name': 'Test Hotel',
        'geoCode': {'latitude': 48.8566, 'longitude': 2.3522},
        'rating': 4.0,
        'address': {
          'lines': ['123 Test Street'],
          'cityName': 'Paris',
          'countryCode': 'FR',
        },
        'amenities': ['WIFI', 'PARKING'],
        'offers': [
          {
            'price': {'total': '100.00', 'currency': 'EUR'},
          },
        ],
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.id, 'test-hotel');
      expect(hotel.name, 'Test Hotel');
      expect(hotel.latitude, 48.8566);
      expect(hotel.longitude, 2.3522);
      expect(hotel.rating, 4.0);
      expect(hotel.address, contains('123 Test Street'));
      expect(hotel.address, contains('Paris'));
      expect(hotel.amenities, ['WIFI', 'PARKING']);
      expect(hotel.pricePerNight, 100.0);
      expect(hotel.currency, 'EUR');
    });

    test('should parse from JSON with direct coordinates', () {
      final json = {
        'id': 'direct-hotel',
        'hotelName': 'Direct Hotel',
        'latitude': 51.5074,
        'longitude': -0.1278,
        'price': 150.0,
        'currency': 'GBP',
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.id, 'direct-hotel');
      expect(hotel.name, 'Direct Hotel');
      expect(hotel.latitude, 51.5074);
      expect(hotel.longitude, -0.1278);
      expect(hotel.pricePerNight, 150.0);
      expect(hotel.currency, 'GBP');
    });

    test('should handle missing optional fields', () {
      final json = {
        'hotelId': 'minimal-hotel',
        'name': 'Minimal Hotel',
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.id, 'minimal-hotel');
      expect(hotel.name, 'Minimal Hotel');
      expect(hotel.latitude, null);
      expect(hotel.longitude, null);
      expect(hotel.pricePerNight, null);
      expect(hotel.rating, null);
      expect(hotel.address, null);
      expect(hotel.amenities, isEmpty);
    });

    test('toJson should serialize correctly', () {
      final hotel = Hotel(
        id: 'json-hotel',
        name: 'JSON Hotel',
        latitude: 48.8566,
        longitude: 2.3522,
        pricePerNight: 99.99,
        currency: 'EUR',
        rating: 4.5,
        address: 'Test Address',
        amenities: ['WIFI'],
      );

      final json = hotel.toJson();

      expect(json['id'], 'json-hotel');
      expect(json['name'], 'JSON Hotel');
      expect(json['latitude'], 48.8566);
      expect(json['longitude'], 2.3522);
      expect(json['pricePerNight'], 99.99);
      expect(json['currency'], 'EUR');
      expect(json['rating'], 4.5);
      expect(json['address'], 'Test Address');
      expect(json['amenities'], ['WIFI']);
    });

    test('should parse address from string', () {
      final json = {
        'hotelId': 'string-addr',
        'name': 'String Address Hotel',
        'address': '123 Simple Street, City',
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.address, '123 Simple Street, City');
    });

    test('should handle integer price as double', () {
      final json = {
        'hotelId': 'int-price',
        'name': 'Integer Price Hotel',
        'pricePerNight': 100,
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.pricePerNight, 100.0);
    });

    test('should handle string price', () {
      final json = {
        'hotelId': 'string-price',
        'name': 'String Price Hotel',
        'price': '125.50',
      };

      final hotel = Hotel.fromJson(json);

      expect(hotel.pricePerNight, 125.50);
    });
  });
}
