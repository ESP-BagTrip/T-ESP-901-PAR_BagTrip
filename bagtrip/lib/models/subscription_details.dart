import 'package:bagtrip/models/payment_method_preview.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_details.freezed.dart';
part 'subscription_details.g.dart';

/// Detailed subscription state shown on the "Manage subscription" screen.
///
/// Mirrors the response of `GET /v1/subscription/me`. Always trust the
/// backend for `plan` — Stripe webhooks are the authoritative source of
/// truth, the local copy is just a snapshot for rendering.
@freezed
abstract class SubscriptionDetails with _$SubscriptionDetails {
  const SubscriptionDetails._();

  const factory SubscriptionDetails({
    required String plan,
    @JsonKey(name: 'cancel_at_period_end')
    @Default(false)
    bool cancelAtPeriodEnd,
    @JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,
    @JsonKey(name: 'plan_expires_at') DateTime? planExpiresAt,
    @JsonKey(name: 'stripe_subscription_id') String? stripeSubscriptionId,
    @JsonKey(name: 'payment_method') PaymentMethodPreview? paymentMethod,
    @JsonKey(name: 'ai_generations_remaining') int? aiGenerationsRemaining,
    @JsonKey(name: 'viewers_per_trip') int? viewersPerTrip,
    @JsonKey(name: 'offline_notifications') bool? offlineNotifications,
    @JsonKey(name: 'post_voyage_ai') bool? postVoyageAi,
  }) = _SubscriptionDetails;

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionDetailsFromJson(json);

  bool get isPremium => plan == 'PREMIUM' || plan == 'ADMIN';
  bool get isFree => plan == 'FREE';
  bool get isAdmin => plan == 'ADMIN';

  /// True when the user has scheduled cancellation but is still in their
  /// paid period. The UI shows "Cancels on Apr 30" rather than "Active".
  bool get isCancelScheduled => isPremium && cancelAtPeriodEnd;

  /// Best-effort renewal/expiry date for display. Prefers the live Stripe
  /// `current_period_end` over the locally cached `plan_expires_at`.
  DateTime? get effectiveRenewalDate => currentPeriodEnd ?? planExpiresAt;
}
