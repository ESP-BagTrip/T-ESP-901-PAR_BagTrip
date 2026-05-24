import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/models/weather_summary.dart';

abstract class WeatherRepository {
  Future<Result<WeatherSummary>> getWeather(String tripId);
}
