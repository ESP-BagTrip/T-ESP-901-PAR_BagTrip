import 'package:dio/dio.dart';

/// Model representing a hotel from the API.
class Hotel {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final double? pricePerNight;
  final String? currency;
  final double? rating;
  final String? address;
  final List<String> amenities;
  final String? imageUrl;

  Hotel({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.pricePerNight,
    this.currency,
    this.rating,
    this.address,
    this.amenities = const [],
    this.imageUrl,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Handle flexible response structure
    final geoCode = json['geoCode'] as Map<String, dynamic>?;
    final offers = json['offers'] as List?;
    final firstOffer = offers?.isNotEmpty == true ? offers!.first as Map<String, dynamic>? : null;
    final price = firstOffer?['price'] as Map<String, dynamic>?;

    return Hotel(
      id: json['hotelId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['hotelName']?.toString() ?? 'Unknown Hotel',
      latitude: _parseDouble(geoCode?['latitude'] ?? json['latitude']),
      longitude: _parseDouble(geoCode?['longitude'] ?? json['longitude']),
      pricePerNight: _parseDouble(price?['total'] ?? json['pricePerNight'] ?? json['price']),
      currency: price?['currency']?.toString() ?? json['currency']?.toString() ?? 'EUR',
      rating: _parseDouble(json['rating']),
      address: _parseAddress(json['address']),
      amenities: _parseAmenities(json['amenities']),
      imageUrl: json['media']?.first?['uri']?.toString() ?? json['imageUrl']?.toString(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _parseAddress(dynamic address) {
    if (address == null) return null;
    if (address is String) return address;
    if (address is Map) {
      final lines = <String>[];
      if (address['lines'] is List) {
        lines.addAll((address['lines'] as List).map((e) => e.toString()));
      }
      if (address['cityName'] != null) {
        lines.add(address['cityName'].toString());
      }
      if (address['countryCode'] != null) {
        lines.add(address['countryCode'].toString());
      }
      return lines.isNotEmpty ? lines.join(', ') : null;
    }
    return null;
  }

  static List<String> _parseAmenities(dynamic amenities) {
    if (amenities == null) return [];
    if (amenities is List) {
      return amenities.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerNight': pricePerNight,
      'currency': currency,
      'rating': rating,
      'address': address,
      'amenities': amenities,
      'imageUrl': imageUrl,
    };
  }
}

/// Service for searching and fetching hotel data.
class HotelService {
  final Dio _dio;
  final String baseUrl = 'http://localhost:3000/v1';

  HotelService({Dio? dio}) : _dio = dio ?? Dio();

  /// Searches for hotels by geographic location.
  ///
  /// [latitude] and [longitude] define the search center.
  /// [checkIn] and [checkOut] are dates in 'YYYY-MM-DD' format.
  /// [adults] is the number of adult guests.
  Future<List<Hotel>> searchHotelsByLocation({
    required double latitude,
    required double longitude,
    required String checkIn,
    required String checkOut,
    int adults = 1,
    int radius = 50,
    String radiusUnit = 'KM',
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/trips/default/hotels/searches',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'checkInDate': checkIn,
          'checkOutDate': checkOut,
          'adults': adults,
          'radius': radius,
          'radiusUnit': radiusUnit,
        },
      );

      return _parseHotelsResponse(response.data);
    } on DioException catch (e) {
      // Try to extract data from error response
      if (e.response?.data != null) {
        try {
          return _parseHotelsResponse(e.response!.data);
        } catch (_) {
          // Fall through to error
        }
      }
      throw Exception('Error searching hotels: ${e.message}');
    } catch (e) {
      throw Exception('Error searching hotels: $e');
    }
  }

  /// Parses the hotels response handling multiple possible formats.
  List<Hotel> _parseHotelsResponse(dynamic data) {
    List<dynamic>? rawHotels;

    if (data is List) {
      rawHotels = data;
    } else if (data is Map) {
      // Try common response keys
      if (data['data'] is List) {
        rawHotels = data['data'] as List;
      } else if (data['hotels'] is List) {
        rawHotels = data['hotels'] as List;
      } else if (data['list'] is List) {
        rawHotels = data['list'] as List;
      } else if (data['results'] is List) {
        rawHotels = data['results'] as List;
      }
    }

    if (rawHotels == null || rawHotels.isEmpty) {
      return [];
    }

    return rawHotels
        .whereType<Map<String, dynamic>>()
        .map((h) => Hotel.fromJson(h))
        .where((h) => h.latitude != null && h.longitude != null)
        .toList();
  }

  /// Gets hotel details by ID.
  Future<Hotel?> getHotelDetails(String hotelId) async {
    try {
      final response = await _dio.get('$baseUrl/hotels/$hotelId');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['hotel'] is Map<String, dynamic>) {
          return Hotel.fromJson(data['hotel'] as Map<String, dynamic>);
        }
        return Hotel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching hotel details: $e');
    }
  }
}
