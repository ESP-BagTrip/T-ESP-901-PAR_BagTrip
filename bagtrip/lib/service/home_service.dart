import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/home_summary.dart';
import 'package:bagtrip/repositories/home_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient _apiClient;

  HomeRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Result<HomeSummary>> getHome() async {
    try {
      final response = await _apiClient.get('/home');
      if (response.statusCode == 200) {
        return Success(
          HomeSummary.fromJson(response.data as Map<String, dynamic>),
        );
      }
      return loggedFailure(
        UnknownError('fetch home failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
