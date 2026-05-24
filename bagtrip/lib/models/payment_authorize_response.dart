import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_authorize_response.freezed.dart';
part 'payment_authorize_response.g.dart';

@freezed
abstract class PaymentAuthorizeResponse with _$PaymentAuthorizeResponse {
  const factory PaymentAuthorizeResponse({
    @JsonKey(name: 'stripePaymentIntentId')
    required String stripePaymentIntentId,
    @JsonKey(name: 'clientSecret') required String clientSecret,
    required String status,
  }) = _PaymentAuthorizeResponse;

  factory PaymentAuthorizeResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentAuthorizeResponseFromJson(json);
}
