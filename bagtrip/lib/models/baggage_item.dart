import 'package:freezed_annotation/freezed_annotation.dart';

part 'baggage_item.freezed.dart';
part 'baggage_item.g.dart';

@freezed
abstract class BaggageItem with _$BaggageItem {
  const factory BaggageItem({
    required String id,
    required String tripId,
    required String name,
    int? quantity,
    @Default(false) bool isPacked,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _BaggageItem;

  factory BaggageItem.fromJson(Map<String, dynamic> json) =>
      _$BaggageItemFromJson(json);
}
