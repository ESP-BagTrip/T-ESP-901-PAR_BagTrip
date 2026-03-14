import 'package:freezed_annotation/freezed_annotation.dart';

part 'baggage_info.freezed.dart';
part 'baggage_info.g.dart';

@freezed
abstract class BaggageInfo with _$BaggageInfo {
  const factory BaggageInfo({int? quantity, int? weight, String? weightUnit}) =
      _BaggageInfo;

  factory BaggageInfo.fromJson(Map<String, dynamic> json) =>
      _$BaggageInfoFromJson(json);
}
