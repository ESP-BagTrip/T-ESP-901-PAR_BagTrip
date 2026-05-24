import 'package:bagtrip/core/app_error.dart';
import 'package:bagtrip/core/result.dart';
import 'package:bagtrip/service/api_client.dart';
import 'package:bagtrip/service/weather_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

Response _response({required int statusCode, Object? data}) => Response(
  requestOptions: RequestOptions(path: '/v1/trips/t-1/weather'),
  statusCode: statusCode,
  data: data,
);

Map<String, dynamic> _weatherJson() => <String, dynamic>{
  'avg_temp_c': 21.5,
  'min_temp_c': 18.0,
  'max_temp_c': 24.0,
  'description': 'Sunny',
  'rain_probability': 10,
  'source': 'open-meteo',
};

void main() {
  late _MockApiClient mockApiClient;
  late WeatherRepositoryImpl repository;

  setUp(() {
    mockApiClient = _MockApiClient();
    repository = WeatherRepositoryImpl(apiClient: mockApiClient);
  });

  group('WeatherRepositoryImpl', () {
    test('getWeather returns Success(WeatherSummary) on 200', () async {
      when(() => mockApiClient.get('/v1/trips/t-1/weather')).thenAnswer(
        (_) async => _response(statusCode: 200, data: _weatherJson()),
      );

      final result = await repository.getWeather('t-1');

      expect(result, isA<Success>());
      final summary = (result as Success).data;
      expect(summary.avgTempC, 21.5);
      expect(summary.minTempC, 18.0);
      expect(summary.maxTempC, 24.0);
      expect(summary.description, 'Sunny');
      expect(summary.rainProbability, 10);
      expect(summary.source, 'open-meteo');
    });

    test('getWeather returns Failure on non-200 status', () async {
      when(() => mockApiClient.get('/v1/trips/t-1/weather')).thenAnswer(
        (_) async => _response(statusCode: 500, data: <String, dynamic>{}),
      );

      final result = await repository.getWeather('t-1');

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });

    test('getWeather maps DioException to Failure', () async {
      when(() => mockApiClient.get('/v1/trips/t-1/weather')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/trips/t-1/weather'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      final result = await repository.getWeather('t-1');

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<NetworkError>());
    });

    test('getWeather wraps non-Dio exception in UnknownError', () async {
      when(
        () => mockApiClient.get('/v1/trips/t-1/weather'),
      ).thenThrow(const FormatException('bad json'));

      final result = await repository.getWeather('t-1');

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<UnknownError>());
    });
  });
}
