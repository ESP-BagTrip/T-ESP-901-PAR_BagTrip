import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/flight_info.dart';
import 'package:bagtrip/models/manual_flight.dart';
import 'package:bagtrip/repositories/transport_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class TransportRepositoryImpl implements TransportRepository {
  final ApiClient _apiClient;

  TransportRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<ManualFlight>> createManualFlight(
    String tripId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/flights/manual',
        data: data,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(ManualFlight.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create manual flight failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<ManualFlight>>> getManualFlights(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/flights/manual');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(
            data.map((json) => ManualFlight.fromJson(json)).toList(),
          );
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List)
                .map((json) => ManualFlight.fromJson(json))
                .toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch manual flights failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteManualFlight(
    String tripId,
    String flightId,
  ) async {
    try {
      final response = await _apiClient.delete(
        '/trips/$tripId/flights/manual/$flightId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete manual flight failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<FlightInfo>> lookupFlight(String flightNumber) async {
    try {
      final code = flightNumber.toUpperCase().trim();
      final response = await _apiClient.get('/travel/flights/$code/info');
      if (response.statusCode == 200) {
        return Success(FlightInfo.fromJson(response.data));
      }
      return loggedFailure(
        NotFoundError('flight info not found: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
