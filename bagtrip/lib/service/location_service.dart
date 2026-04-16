import 'package:bagtrip/config/app_config.dart';
import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/flight_search_result/models/flight.dart';
import 'package:bagtrip/flight_search/models/flight_segment.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class LocationService {
  final Dio _dio;
  final String baseUrl = AppConfig.apiBaseUrl;
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};

  LocationService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Result<List<Flight>>> searchFlights({
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
      // Multi-destination search is handled by the persisted endpoint
      // via TransportRepository.searchMultiDestFlights() — this method
      // only handles single-segment proxy searches as a fallback.

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

        var flights = rawFlights
            .map(
              (json) =>
                  Flight.fromAmadeusJson(json, dictionaries: dictionaries),
            )
            .toList();

        return Success(flights);
      }
      return loggedFailure(
        ServerError(
          'Failed to fetch flights: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(
        UnknownError('Error searching flights: $e', originalError: e),
      );
    }
  }

  Map<String, dynamic> _flattenLocation(Map<String, dynamic> loc) {
    if (loc['address'] is Map) {
      final address = loc['address'] as Map;
      loc['city'] = address['cityName'];
      loc['countryCode'] = address['countryCode'];
      loc['countryName'] = address['countryName'];
    }
    return loc;
  }

  Future<Result<List<Map<String, dynamic>>>> searchLocationsByKeyword(
    String keyword,
    String subType,
  ) async {
    final cacheKey = '${keyword.toLowerCase().trim()}|$subType';
    if (_searchCache.containsKey(cacheKey)) {
      return Success(_searchCache[cacheKey]!);
    }

    try {
      final response = await _dio.get(
        '$baseUrl/travel/locations',
        queryParameters: {'keyword': keyword, 'subType': subType},
      );

      final data = response.data;
      List<Map<String, dynamic>>? results;

      // The API can return either a raw array or an object like { locations: [...], count: N }
      if (data is List) {
        results = List<Map<String, dynamic>>.from(
          data.map(
            (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
          ),
        );
      } else if (data is Map) {
        // try common keys
        if (data['locations'] is List) {
          results = List<Map<String, dynamic>>.from(
            (data['locations'] as List).map(
              (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
            ),
          );
        } else if (data['data'] is List) {
          results = List<Map<String, dynamic>>.from(
            (data['data'] as List).map(
              (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
            ),
          );
        } else if (data.isNotEmpty) {
          // If the response is a single object, wrap it into a list
          try {
            final m = _flattenLocation(Map<String, dynamic>.from(data));
            results = [m];
          } catch (_) {
            // fallthrough
          }
        }
      }

      // Return valid results (including empty list) when parsing succeeded.
      if (results != null) {
        if (results.isNotEmpty) {
          _searchCache[cacheKey] = results;
        }
        return Success(results);
      }

      // Could not parse any results — non-200 means upstream error.
      if (response.statusCode != 200) {
        return loggedFailure(
          ServerError(
            'Failed to fetch locations: HTTP ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      }

      // 200 but unrecognized shape — return empty list rather than error.
      return const Success([]);
    } on DioException catch (e) {
      // For Dio errors, check if response body contains usable data.
      if (e.response?.data != null) {
        try {
          final data = e.response!.data;
          List<Map<String, dynamic>>? results;

          if (data is List) {
            results = List<Map<String, dynamic>>.from(
              data.map(
                (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
              ),
            );
          } else if (data is Map) {
            if (data['locations'] is List) {
              results = List<Map<String, dynamic>>.from(
                (data['locations'] as List).map(
                  (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
                ),
              );
            } else if (data['data'] is List) {
              results = List<Map<String, dynamic>>.from(
                (data['data'] as List).map(
                  (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
                ),
              );
            }
          }

          // Return valid results even when status code indicates an error.
          if (results != null && results.isNotEmpty) {
            _searchCache[cacheKey] = results;
            return Success(results);
          }
        } catch (_) {
          // If parsing fails, fall through to return network error.
        }
      }

      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(
        UnknownError('Error searching locations: $e', originalError: e),
      );
    }
  }

  Future<Result<List<Map<String, dynamic>>>> searchNearestLocations(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _dio.get(
        '$baseUrl/travel/locations/nearest',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );

      final data = response.data;
      List<Map<String, dynamic>>? results;

      if (data is List) {
        results = List<Map<String, dynamic>>.from(
          data.map(
            (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
          ),
        );
      } else if (data is Map) {
        if (data['locations'] is List) {
          results = List<Map<String, dynamic>>.from(
            (data['locations'] as List).map(
              (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
            ),
          );
        } else if (data['data'] is List) {
          results = List<Map<String, dynamic>>.from(
            (data['data'] as List).map(
              (e) => _flattenLocation(Map<String, dynamic>.from(e as Map)),
            ),
          );
        }
      }

      return Success(results ?? []);
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(
        UnknownError('Error searching nearest locations: $e', originalError: e),
      );
    }
  }
}
