import 'package:freezed_annotation/freezed_annotation.dart';

part 'suggested_baggage_item.freezed.dart';
part 'suggested_baggage_item.g.dart';

@freezed
abstract class SuggestedBaggageItem with _$SuggestedBaggageItem {
  const factory SuggestedBaggageItem({
    required String name,
    @Default(1) int quantity,
    @Default('Autre') String category,
    String? reason,
  }) = _SuggestedBaggageItem;

  factory SuggestedBaggageItem.fromJson(Map<String, dynamic> json) =>
      _$SuggestedBaggageItemFromJson(json);
}
