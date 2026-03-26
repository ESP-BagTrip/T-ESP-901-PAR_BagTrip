import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/logged_failure.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/weather_summary.dart';
import 'package:bagtrip/repositories/weather_repository.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:dio/dio.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final ApiClient _apiClient;

  WeatherRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<Result<WeatherSummary>> getWeather(String tripId) async {
    try {
      final response = await _apiClient.get('/v1/trips/$tripId/weather');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Success(WeatherSummary.fromJson(data));
      }
      return loggedFailure(
        UnknownError('fetch weather failed: ${response.statusCode}'),
      );
    } on DioException catch (e) {
      return loggedFailure(ApiClient.mapDioError(e));
    } catch (e) {
      return loggedFailure(UnknownError(e.toString(), originalError: e));
    }
  }
}
