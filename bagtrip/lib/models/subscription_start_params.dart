import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_start_params.freezed.dart';
part 'subscription_start_params.g.dart';

/// Bootstrap payload for the deferred-IntentConfiguration PaymentSheet.
///
/// Mirrors `POST /v1/subscription/start`. Just enough to render the
/// PaymentSheet — `customer` + `ephemeralKey` for saved-card lookup,
/// `amount` + `currency` for the price line. The actual `Subscription`
/// is created in `POST /v1/subscription/confirm` once the user has
/// chosen a payment method and tapped Pay (deferred flow).
@freezed
abstract class SubscriptionStartParams with _$SubscriptionStartParams {
  const factory SubscriptionStartParams({
    required String customer,
    @JsonKey(name: 'ephemeral_key') required String ephemeralKey,
    required int amount,
    required String currency,
  }) = _SubscriptionStartParams;

  factory SubscriptionStartParams.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStartParamsFromJson(json);
}
