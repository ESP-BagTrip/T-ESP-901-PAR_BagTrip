import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_start_params.freezed.dart';
part 'subscription_start_params.g.dart';

/// Bootstrap payload for the native PaymentSheet subscription flow.
///
/// Mirrors `POST /v1/subscription/start`. The trio
/// `paymentIntentClientSecret` + `ephemeralKey` + `customer` is exactly
/// what `Stripe.instance.initPaymentSheet(...)` consumes — we never
/// pass a Checkout URL and never leave the app.
@freezed
abstract class SubscriptionStartParams with _$SubscriptionStartParams {
  const factory SubscriptionStartParams({
    @JsonKey(name: 'subscription_id') required String subscriptionId,
    @JsonKey(name: 'payment_intent_client_secret')
    required String paymentIntentClientSecret,
    @JsonKey(name: 'ephemeral_key') required String ephemeralKey,
    required String customer,
  }) = _SubscriptionStartParams;

  factory SubscriptionStartParams.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStartParamsFromJson(json);
}
