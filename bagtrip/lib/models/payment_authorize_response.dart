import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_authorize_response.freezed.dart';
part 'payment_authorize_response.g.dart';

@freezed
abstract class PaymentAuthorizeResponse with _$PaymentAuthorizeResponse {
  const factory PaymentAuthorizeResponse({
    required String stripePaymentIntentId,
    required String clientSecret,
    required String status,
  }) = _PaymentAuthorizeResponse;

  factory PaymentAuthorizeResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentAuthorizeResponseFromJson(json);
}
