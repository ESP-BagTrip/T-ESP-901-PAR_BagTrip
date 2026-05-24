import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_setup_params.freezed.dart';
part 'payment_method_setup_params.g.dart';

/// Bootstrap payload for the in-app payment method update flow.
///
/// Mirrors `POST /v1/subscription/payment-method/setup`. Drives the
/// PaymentSheet in setup mode — the user attaches a new card without
/// ever leaving the app, then we POST the resulting PaymentMethod id
/// to `/payment-method/attach` so the next renewal charges the new card.
@freezed
abstract class PaymentMethodSetupParams with _$PaymentMethodSetupParams {
  const factory PaymentMethodSetupParams({
    @JsonKey(name: 'setup_intent_client_secret')
    required String setupIntentClientSecret,
    @JsonKey(name: 'ephemeral_key') required String ephemeralKey,
    required String customer,
  }) = _PaymentMethodSetupParams;

  factory PaymentMethodSetupParams.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodSetupParamsFromJson(json);
}
