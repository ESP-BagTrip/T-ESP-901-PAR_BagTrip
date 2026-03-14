import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/traveler.dart';
import 'package:bagtrip/repositories/traveler_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class TravelerRepositoryImpl implements TravelerRepository {
  final ApiClient _apiClient;

  TravelerRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<Traveler>> createTraveler(
    String tripId, {
    String? amadeusTravelerRef,
    required String travelerType,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? gender,
    List<Map<String, dynamic>>? documents,
    Map<String, dynamic>? contacts,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/travelers',
        data: {
          if (amadeusTravelerRef != null)
            'amadeusTravelerRef': amadeusTravelerRef,
          'travelerType': travelerType,
          'firstName': firstName,
          'lastName': lastName,
          if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
          if (gender != null) 'gender': gender,
          if (documents != null) 'documents': documents,
          if (contacts != null) 'contacts': contacts,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(Traveler.fromJson(response.data));
      }
      return Failure(
        UnknownError('create traveler failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Traveler>>> getTravelersByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/travelers');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(data.map((json) => Traveler.fromJson(json)).toList());
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => Traveler.fromJson(json))
                .toList(),
          );
        }
        return const Success([]);
      }
      return Failure(
        UnknownError('fetch travelers failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Traveler>> updateTraveler(
    String tripId,
    String travelerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/travelers/$travelerId',
        data: updates,
      );
      if (response.statusCode == 200) {
        return Success(Traveler.fromJson(response.data));
      }
      return Failure(
        UnknownError('update traveler failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteTraveler(String tripId, String travelerId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/travelers/$travelerId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return Failure(
        UnknownError('delete traveler failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return Failure(ApiClient.mapDioError(e));
    } catch (e) {
      return Failure(UnknownError(e.toString(), originalError: e));
    }
  }
}
