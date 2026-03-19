import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_card.freezed.dart';
part 'payment_card.g.dart';

@freezed
abstract class PaymentCard with _$PaymentCard {
  const factory PaymentCard({
    required String id,
    @JsonKey(name: 'lastFourDigits') required String lastFourDigits,
    @JsonKey(name: 'expiryDate') required String expiryDate,
    @JsonKey(name: 'isDefault') required bool isDefault,
  }) = _PaymentCard;

  factory PaymentCard.fromJson(Map<String, dynamic> json) =>
      _$PaymentCardFromJson(json);
}
