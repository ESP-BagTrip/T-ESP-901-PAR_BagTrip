import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_summary.freezed.dart';
part 'weather_summary.g.dart';

@freezed
abstract class WeatherSummary with _$WeatherSummary {
  const factory WeatherSummary({
    @JsonKey(name: 'avg_temp_c') required double avgTempC,
    @JsonKey(name: 'min_temp_c') double? minTempC,
    @JsonKey(name: 'max_temp_c') double? maxTempC,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'rain_probability') @Default(0) int rainProbability,
    @JsonKey(name: 'source') @Default('unknown') String source,
  }) = _WeatherSummary;

  factory WeatherSummary.fromJson(Map<String, dynamic> json) =>
      _$WeatherSummaryFromJson(json);
}
