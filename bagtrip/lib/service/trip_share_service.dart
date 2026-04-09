import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip_share.dart';
import 'package:bagtrip/repositories/trip_share_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class TripShareRepositoryImpl implements TripShareRepository {
  final ApiClient _apiClient;

  TripShareRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<TripShare>> createShare(
    String tripId, {
    required String email,
    String? message,
    String role = 'VIEWER',
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/shares',
        data: {
          'email': email,
          'role': role,
          if (message != null) 'message': message,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(TripShare.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create share failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<TripShare>>> getSharesByTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/shares');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => TripShare.fromJson(json))
                .toList(),
          );
        }
        if (data is List) {
          return Success(data.map((json) => TripShare.fromJson(json)).toList());
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch shares failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteShare(String tripId, String shareId) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/shares/$shareId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete share failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
