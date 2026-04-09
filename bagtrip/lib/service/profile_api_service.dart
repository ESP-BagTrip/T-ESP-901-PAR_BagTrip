import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/traveler_profile.dart';
import 'package:bagtrip/repositories/profile_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Result<TravelerProfile>> getProfile() async {
    try {
      final response = await _apiClient.get('/profile');
      return Success(
        TravelerProfile.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<TravelerProfile>> updateProfile({
    List<String>? travelTypes,
    String? travelStyle,
    String? budget,
    String? companions,
    String? travelFrequency,
    String? medicalConstraints,
  }) async {
    try {
      final response = await _apiClient.put(
        '/profile',
        data: {
          if (travelTypes != null) 'travelTypes': travelTypes,
          if (travelStyle != null) 'travelStyle': travelStyle,
          if (budget != null) 'budget': budget,
          if (companions != null) 'companions': companions,
          if (travelFrequency != null) 'travelFrequency': travelFrequency,
          if (medicalConstraints != null)
            'medicalConstraints': medicalConstraints,
        },
      );
      return Success(
        TravelerProfile.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }

  @override
  Future<Result<ProfileCompletion>> checkCompletion() async {
    try {
      final response = await _apiClient.get('/profile/completion');
      return Success(
        ProfileCompletion.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
