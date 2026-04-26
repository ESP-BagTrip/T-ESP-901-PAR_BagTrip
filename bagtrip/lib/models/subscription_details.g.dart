// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubscriptionDetails _$SubscriptionDetailsFromJson(Map<String, dynamic> json) =>
    _SubscriptionDetails(
      plan: json['plan'] as String,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      planExpiresAt: json['plan_expires_at'] == null
          ? null
          : DateTime.parse(json['plan_expires_at'] as String),
      stripeSubscriptionId: json['stripe_subscription_id'] as String?,
      paymentMethod: json['payment_method'] == null
          ? null
          : PaymentMethodPreview.fromJson(
              json['payment_method'] as Map<String, dynamic>,
            ),
      aiGenerationsRemaining: (json['ai_generations_remaining'] as num?)
          ?.toInt(),
      viewersPerTrip: (json['viewers_per_trip'] as num?)?.toInt(),
      offlineNotifications: json['offline_notifications'] as bool?,
      postVoyageAi: json['post_voyage_ai'] as bool?,
    );

Map<String, dynamic> _$SubscriptionDetailsToJson(
  _SubscriptionDetails instance,
) => <String, dynamic>{
  'plan': instance.plan,
  'cancel_at_period_end': instance.cancelAtPeriodEnd,
  'current_period_end': instance.currentPeriodEnd?.toIso8601String(),
  'plan_expires_at': instance.planExpiresAt?.toIso8601String(),
  'stripe_subscription_id': instance.stripeSubscriptionId,
  'payment_method': instance.paymentMethod?.toJson(),
  'ai_generations_remaining': instance.aiGenerationsRemaining,
  'viewers_per_trip': instance.viewersPerTrip,
  'offline_notifications': instance.offlineNotifications,
  'post_voyage_ai': instance.postVoyageAi,
};
