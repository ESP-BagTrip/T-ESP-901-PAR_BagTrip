import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/paginated_response.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/trip.dart';
import 'package:bagtrip/models/trip_grouped.dart';
import 'package:bagtrip/models/trip_home.dart';
import 'package:bagtrip/repositories/trip_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class TripRepositoryImpl implements TripRepository {
  final ApiClient _apiClient;

  TripRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Result<Trip>> createTrip({
    required String title,
    String? originIata,
    String? destinationIata,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? destinationName,
    int? nbTravelers,
    String? coverImageUrl,
    double? budgetTarget,
    String? origin,
  }) async {
    try {
      final response = await _apiClient.post(
        '/trips',
        data: {
          'title': title,
          if (originIata != null) 'originIata': originIata,
          if (destinationIata != null) 'destinationIata': destinationIata,
          if (startDate != null)
            'startDate': DateTime(
              startDate.year,
              startDate.month,
              startDate.day,
            ).toIso8601String(),
          if (endDate != null)
            'endDate': DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            ).toIso8601String(),
          if (description != null) 'description': description,
          if (destinationName != null) 'destinationName': destinationName,
          if (nbTravelers != null) 'nbTravelers': nbTravelers,
          if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
          if (budgetTarget != null) 'budgetTarget': budgetTarget,
          if (origin != null) 'origin': origin,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Success(Trip.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('create trip failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<List<Trip>>> getTrips() async {
    try {
      final response = await _apiClient.get('/trips');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return Success(data.map((json) => Trip.fromJson(json)).toList());
        } else if (data is Map && data['items'] is List) {
          return Success(
            (data['items'] as List).map((json) => Trip.fromJson(json)).toList(),
          );
        }
        return const Success([]);
      }
      return loggedFailure(
        UnknownError('fetch trips failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<PaginatedResponse<Trip>>> getTripsPaginated({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) queryParams['status'] = status;
      final response = await _apiClient.get(
        '/trips',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map((json) => Trip.fromJson(json))
            .toList();
        return Success(
          PaginatedResponse<Trip>(
            items: items,
            total: data['total'] as int,
            page: data['page'] as int,
            totalPages: (data['total_pages'] ?? data['totalPages'] ?? 0) as int,
          ),
        );
      }
      return loggedFailure(
        UnknownError('fetch trips paginated failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<TripGrouped>> getGroupedTrips() async {
    try {
      final response = await _apiClient.get('/trips/grouped');
      if (response.statusCode == 200) {
        return Success(
          TripGrouped.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('fetch grouped trips failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<TripHome>> getTripHome(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/home');
      if (response.statusCode == 200) {
        return Success(
          TripHome.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('fetch trip home failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Trip>> getTripById(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['trip'] != null) {
          return Success(Trip.fromJson(data['trip'] as Map<String, dynamic>));
        }
        return Success(Trip.fromJson(data));
      }
      return loggedFailure(
        UnknownError('fetch trip failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Trip>> updateTripStatus(String tripId, String status) async {
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/status',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        return Success(Trip.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update trip status failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Trip>> updateTripTracking(
    String tripId, {
    String? flightsTracking,
    String? accommodationsTracking,
  }) async {
    final data = <String, dynamic>{
      if (flightsTracking != null) 'flightsTracking': flightsTracking,
      if (accommodationsTracking != null)
        'accommodationsTracking': accommodationsTracking,
    };
    if (data.isEmpty) {
      return loggedFailure(
        const ValidationError('updateTripTracking: no flag provided'),
      );
    }
    try {
      final response = await _apiClient.patch(
        '/trips/$tripId/tracking',
        data: data,
      );
      if (response.statusCode == 200) {
        return Success(Trip.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update trip tracking failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<Trip>> updateTrip(
    String tripId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.patch('/trips/$tripId', data: updates);
      if (response.statusCode == 200) {
        return Success(Trip.fromJson(response.data));
      }
      return loggedFailure(
        UnknownError('update trip failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<void>> deleteTrip(String tripId) async {
    try {
      final response = await _apiClient.delete('/trips/$tripId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
      }
      return loggedFailure(
        UnknownError('delete trip failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
