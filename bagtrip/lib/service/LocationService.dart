// ignore_for_file: file_names

import 'package:dio/dio.dart';

class LocationService {
  final Dio _dio = Dio();
  final String baseUrl =
      'http://localhost:3000/api';

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
