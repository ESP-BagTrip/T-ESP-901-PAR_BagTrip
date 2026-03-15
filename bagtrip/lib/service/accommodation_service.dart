import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/accommodation.dart';
import 'package:bagtrip/repositories/accommodation_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class AccommodationRepositoryImpl implements AccommodationRepository {
  final ApiClient _apiClient;

  AccommodationRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<Accommodation>> createAccommodation(
    String tripId, {
    required String name,
    String? address,
    DateTime? checkIn,
    DateTime? checkOut,
    double? pricePerNight,
    String? currency,
    String? bookingReference,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/accommodations',
        data: {
          'name': name,
          if (address != null) 'address': address,
          if (checkIn != null)
            'checkIn': checkIn.toIso8601String().split('T').first,
          if (checkOut != null)
            'checkOut': checkOut.toIso8601String().split('T').first,
          if (pricePerNight != null) 'pricePerNight': pricePerNight,
          if (currency != null) 'currency': currency,
          if (bookingReference != null) 'bookingReference': bookingReference,
          if (notes != null) 'notes': notes,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(Accommodation.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create accommodation failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Accommodation>>> getByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/accommodations');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(
            data.map((json) => Accommodation.fromJson(json)).toList(),
          );
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => Accommodation.fromJson(json))
                .toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch accommodations failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Accommodation>> updateAccommodation(
    String tripId,
    String accommodationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/accommodations/$accommodationId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Success(Accommodation.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update accommodation failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteAccommodation(
    String tripId,
    String accommodationId,
  ) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/accommodations/$accommodationId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete accommodation failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
