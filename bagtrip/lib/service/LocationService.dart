// ignore_for_file: file_names

import 'package:bagtrip/flightSearchResult/models/flight.dart';
import 'package:bagtrip/home/models/flight_segment.dart';
import 'package:dio/dio.dart';

class LocationService {
  final Dio _dio = Dio();
  final String baseUrl = 'http://localhost:3000/v1';

  Future<List<Flight>> searchFlights({
    required String departureCode,
    required String arrivalCode,
    required String departureDate,
    String? returnDate,
    required int adults,
    int children = 0,
    int infants = 0,
    String travelClass = 'ECONOMY',
    List<FlightSegment>? multiDestSegments,
  }) async {
    try {
      if (multiDestSegments != null && multiDestSegments.isNotEmpty) {
        // TODO: Implement multi-destination search when backend supports it
        // For now, we can either throw or just search for the first segment
        // throw UnimplementedError("Multi-destination search not yet supported by backend");
      }

      final queryParameters = {
        'originLocationCode': departureCode,
        'destinationLocationCode': arrivalCode,
        'departureDate': departureDate,
        'adults': adults,
        'children': children,
        'infants': infants,
        'travelClass': travelClass,
        'currencyCode': 'EUR',
      };

      if (returnDate != null) {
        queryParameters['returnDate'] = returnDate;
      }

      // Using the standard Amadeus endpoint structure based on the base URL
      final response = await _dio.get(
        '$baseUrl/travel/flight/offers',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> rawFlights = [];
        Map<String, dynamic>? dictionaries;

        if (data is List) {
          rawFlights = data;
        } else if (data is Map) {
          if (data.containsKey('data') && data['data'] is List) {
            rawFlights = data['data'];
          }
          if (data.containsKey('dictionaries') && data['dictionaries'] is Map) {
            dictionaries = Map<String, dynamic>.from(data['dictionaries']);
          }
        }

        var flights =
            rawFlights
                .map(
                  (json) =>
                      Flight.fromAmadeusJson(json, dictionaries: dictionaries),
                )
                .toList();

        return flights;
      }
      throw Exception('Failed to fetch flights: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error searching flights: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchLocationsByKeyword(
    String keyword,
    String subType,
  ) async {
    try {
      final response = await _dio.get(
        '$baseUrl/travel/locations',
        queryParameters: {'keyword': keyword, 'subType': subType},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // The API can return either a raw array or an object like { locations: [...], count: N }
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e as Map)),
          );
        }

        if (data is Map) {
          // try common keys
          if (data['locations'] is List) {
            return List<Map<String, dynamic>>.from(
              (data['locations'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            );
          }

          if (data['data'] is List) {
            return List<Map<String, dynamic>>.from(
              (data['data'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            );
          }

          // If the response is a single object, wrap it into a list
          if (data.isNotEmpty) {
            try {
              final m = Map<String, dynamic>.from(data);
              return [m];
            } catch (_) {
              // fallthrough
            }
          }
        }

        throw Exception('Unexpected response shape when fetching locations');
      }
      throw Exception('Failed to fetch locations: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error searching locations: $e');
    }
  }
}
