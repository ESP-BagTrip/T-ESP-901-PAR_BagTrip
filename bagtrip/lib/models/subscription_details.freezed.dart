// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionDetails {

 String get plan;@JsonKey(name: 'cancel_at_period_end') bool get cancelAtPeriodEnd;@JsonKey(name: 'current_period_end') DateTime? get currentPeriodEnd;@JsonKey(name: 'plan_expires_at') DateTime? get planExpiresAt;@JsonKey(name: 'stripe_subscription_id') String? get stripeSubscriptionId;@JsonKey(name: 'payment_method') PaymentMethodPreview? get paymentMethod;@JsonKey(name: 'ai_generations_remaining') int? get aiGenerationsRemaining;@JsonKey(name: 'viewers_per_trip') int? get viewersPerTrip;@JsonKey(name: 'offline_notifications') bool? get offlineNotifications;@JsonKey(name: 'post_voyage_ai') bool? get postVoyageAi;
/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionDetailsCopyWith<SubscriptionDetails> get copyWith => _$SubscriptionDetailsCopyWithImpl<SubscriptionDetails>(this as SubscriptionDetails, _$identity);

  /// Serializes this SubscriptionDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionDetails&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.planExpiresAt, planExpiresAt) || other.planExpiresAt == planExpiresAt)&&(identical(other.stripeSubscriptionId, stripeSubscriptionId) || other.stripeSubscriptionId == stripeSubscriptionId)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.aiGenerationsRemaining, aiGenerationsRemaining) || other.aiGenerationsRemaining == aiGenerationsRemaining)&&(identical(other.viewersPerTrip, viewersPerTrip) || other.viewersPerTrip == viewersPerTrip)&&(identical(other.offlineNotifications, offlineNotifications) || other.offlineNotifications == offlineNotifications)&&(identical(other.postVoyageAi, postVoyageAi) || other.postVoyageAi == postVoyageAi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,cancelAtPeriodEnd,currentPeriodEnd,planExpiresAt,stripeSubscriptionId,paymentMethod,aiGenerationsRemaining,viewersPerTrip,offlineNotifications,postVoyageAi);

@override
String toString() {
  return 'SubscriptionDetails(plan: $plan, cancelAtPeriodEnd: $cancelAtPeriodEnd, currentPeriodEnd: $currentPeriodEnd, planExpiresAt: $planExpiresAt, stripeSubscriptionId: $stripeSubscriptionId, paymentMethod: $paymentMethod, aiGenerationsRemaining: $aiGenerationsRemaining, viewersPerTrip: $viewersPerTrip, offlineNotifications: $offlineNotifications, postVoyageAi: $postVoyageAi)';
}


}

/// @nodoc
abstract mixin class $SubscriptionDetailsCopyWith<$Res>  {
  factory $SubscriptionDetailsCopyWith(SubscriptionDetails value, $Res Function(SubscriptionDetails) _then) = _$SubscriptionDetailsCopyWithImpl;
@useResult
$Res call({
 String plan,@JsonKey(name: 'cancel_at_period_end') bool cancelAtPeriodEnd,@JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,@JsonKey(name: 'plan_expires_at') DateTime? planExpiresAt,@JsonKey(name: 'stripe_subscription_id') String? stripeSubscriptionId,@JsonKey(name: 'payment_method') PaymentMethodPreview? paymentMethod,@JsonKey(name: 'ai_generations_remaining') int? aiGenerationsRemaining,@JsonKey(name: 'viewers_per_trip') int? viewersPerTrip,@JsonKey(name: 'offline_notifications') bool? offlineNotifications,@JsonKey(name: 'post_voyage_ai') bool? postVoyageAi
});


$PaymentMethodPreviewCopyWith<$Res>? get paymentMethod;

}
/// @nodoc
class _$SubscriptionDetailsCopyWithImpl<$Res>
    implements $SubscriptionDetailsCopyWith<$Res> {
  _$SubscriptionDetailsCopyWithImpl(this._self, this._then);

  final SubscriptionDetails _self;
  final $Res Function(SubscriptionDetails) _then;

/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? cancelAtPeriodEnd = null,Object? currentPeriodEnd = freezed,Object? planExpiresAt = freezed,Object? stripeSubscriptionId = freezed,Object? paymentMethod = freezed,Object? aiGenerationsRemaining = freezed,Object? viewersPerTrip = freezed,Object? offlineNotifications = freezed,Object? postVoyageAi = freezed,}) {
  return _then(_self.copyWith(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,planExpiresAt: freezed == planExpiresAt ? _self.planExpiresAt : planExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stripeSubscriptionId: freezed == stripeSubscriptionId ? _self.stripeSubscriptionId : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethodPreview?,aiGenerationsRemaining: freezed == aiGenerationsRemaining ? _self.aiGenerationsRemaining : aiGenerationsRemaining // ignore: cast_nullable_to_non_nullable
as int?,viewersPerTrip: freezed == viewersPerTrip ? _self.viewersPerTrip : viewersPerTrip // ignore: cast_nullable_to_non_nullable
as int?,offlineNotifications: freezed == offlineNotifications ? _self.offlineNotifications : offlineNotifications // ignore: cast_nullable_to_non_nullable
as bool?,postVoyageAi: freezed == postVoyageAi ? _self.postVoyageAi : postVoyageAi // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodPreviewCopyWith<$Res>? get paymentMethod {
    if (_self.paymentMethod == null) {
    return null;
  }

  return $PaymentMethodPreviewCopyWith<$Res>(_self.paymentMethod!, (value) {
    return _then(_self.copyWith(paymentMethod: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscriptionDetails].
extension SubscriptionDetailsPatterns on SubscriptionDetails {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionDetails() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionDetails value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionDetails():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionDetails value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionDetails() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plan, @JsonKey(name: 'cancel_at_period_end')  bool cancelAtPeriodEnd, @JsonKey(name: 'current_period_end')  DateTime? currentPeriodEnd, @JsonKey(name: 'plan_expires_at')  DateTime? planExpiresAt, @JsonKey(name: 'stripe_subscription_id')  String? stripeSubscriptionId, @JsonKey(name: 'payment_method')  PaymentMethodPreview? paymentMethod, @JsonKey(name: 'ai_generations_remaining')  int? aiGenerationsRemaining, @JsonKey(name: 'viewers_per_trip')  int? viewersPerTrip, @JsonKey(name: 'offline_notifications')  bool? offlineNotifications, @JsonKey(name: 'post_voyage_ai')  bool? postVoyageAi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionDetails() when $default != null:
return $default(_that.plan,_that.cancelAtPeriodEnd,_that.currentPeriodEnd,_that.planExpiresAt,_that.stripeSubscriptionId,_that.paymentMethod,_that.aiGenerationsRemaining,_that.viewersPerTrip,_that.offlineNotifications,_that.postVoyageAi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plan, @JsonKey(name: 'cancel_at_period_end')  bool cancelAtPeriodEnd, @JsonKey(name: 'current_period_end')  DateTime? currentPeriodEnd, @JsonKey(name: 'plan_expires_at')  DateTime? planExpiresAt, @JsonKey(name: 'stripe_subscription_id')  String? stripeSubscriptionId, @JsonKey(name: 'payment_method')  PaymentMethodPreview? paymentMethod, @JsonKey(name: 'ai_generations_remaining')  int? aiGenerationsRemaining, @JsonKey(name: 'viewers_per_trip')  int? viewersPerTrip, @JsonKey(name: 'offline_notifications')  bool? offlineNotifications, @JsonKey(name: 'post_voyage_ai')  bool? postVoyageAi)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionDetails():
return $default(_that.plan,_that.cancelAtPeriodEnd,_that.currentPeriodEnd,_that.planExpiresAt,_that.stripeSubscriptionId,_that.paymentMethod,_that.aiGenerationsRemaining,_that.viewersPerTrip,_that.offlineNotifications,_that.postVoyageAi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plan, @JsonKey(name: 'cancel_at_period_end')  bool cancelAtPeriodEnd, @JsonKey(name: 'current_period_end')  DateTime? currentPeriodEnd, @JsonKey(name: 'plan_expires_at')  DateTime? planExpiresAt, @JsonKey(name: 'stripe_subscription_id')  String? stripeSubscriptionId, @JsonKey(name: 'payment_method')  PaymentMethodPreview? paymentMethod, @JsonKey(name: 'ai_generations_remaining')  int? aiGenerationsRemaining, @JsonKey(name: 'viewers_per_trip')  int? viewersPerTrip, @JsonKey(name: 'offline_notifications')  bool? offlineNotifications, @JsonKey(name: 'post_voyage_ai')  bool? postVoyageAi)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionDetails() when $default != null:
return $default(_that.plan,_that.cancelAtPeriodEnd,_that.currentPeriodEnd,_that.planExpiresAt,_that.stripeSubscriptionId,_that.paymentMethod,_that.aiGenerationsRemaining,_that.viewersPerTrip,_that.offlineNotifications,_that.postVoyageAi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionDetails extends SubscriptionDetails {
  const _SubscriptionDetails({required this.plan, @JsonKey(name: 'cancel_at_period_end') this.cancelAtPeriodEnd = false, @JsonKey(name: 'current_period_end') this.currentPeriodEnd, @JsonKey(name: 'plan_expires_at') this.planExpiresAt, @JsonKey(name: 'stripe_subscription_id') this.stripeSubscriptionId, @JsonKey(name: 'payment_method') this.paymentMethod, @JsonKey(name: 'ai_generations_remaining') this.aiGenerationsRemaining, @JsonKey(name: 'viewers_per_trip') this.viewersPerTrip, @JsonKey(name: 'offline_notifications') this.offlineNotifications, @JsonKey(name: 'post_voyage_ai') this.postVoyageAi}): super._();
  factory _SubscriptionDetails.fromJson(Map<String, dynamic> json) => _$SubscriptionDetailsFromJson(json);

@override final  String plan;
@override@JsonKey(name: 'cancel_at_period_end') final  bool cancelAtPeriodEnd;
@override@JsonKey(name: 'current_period_end') final  DateTime? currentPeriodEnd;
@override@JsonKey(name: 'plan_expires_at') final  DateTime? planExpiresAt;
@override@JsonKey(name: 'stripe_subscription_id') final  String? stripeSubscriptionId;
@override@JsonKey(name: 'payment_method') final  PaymentMethodPreview? paymentMethod;
@override@JsonKey(name: 'ai_generations_remaining') final  int? aiGenerationsRemaining;
@override@JsonKey(name: 'viewers_per_trip') final  int? viewersPerTrip;
@override@JsonKey(name: 'offline_notifications') final  bool? offlineNotifications;
@override@JsonKey(name: 'post_voyage_ai') final  bool? postVoyageAi;

/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionDetailsCopyWith<_SubscriptionDetails> get copyWith => __$SubscriptionDetailsCopyWithImpl<_SubscriptionDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionDetails&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.cancelAtPeriodEnd, cancelAtPeriodEnd) || other.cancelAtPeriodEnd == cancelAtPeriodEnd)&&(identical(other.currentPeriodEnd, currentPeriodEnd) || other.currentPeriodEnd == currentPeriodEnd)&&(identical(other.planExpiresAt, planExpiresAt) || other.planExpiresAt == planExpiresAt)&&(identical(other.stripeSubscriptionId, stripeSubscriptionId) || other.stripeSubscriptionId == stripeSubscriptionId)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.aiGenerationsRemaining, aiGenerationsRemaining) || other.aiGenerationsRemaining == aiGenerationsRemaining)&&(identical(other.viewersPerTrip, viewersPerTrip) || other.viewersPerTrip == viewersPerTrip)&&(identical(other.offlineNotifications, offlineNotifications) || other.offlineNotifications == offlineNotifications)&&(identical(other.postVoyageAi, postVoyageAi) || other.postVoyageAi == postVoyageAi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plan,cancelAtPeriodEnd,currentPeriodEnd,planExpiresAt,stripeSubscriptionId,paymentMethod,aiGenerationsRemaining,viewersPerTrip,offlineNotifications,postVoyageAi);

@override
String toString() {
  return 'SubscriptionDetails(plan: $plan, cancelAtPeriodEnd: $cancelAtPeriodEnd, currentPeriodEnd: $currentPeriodEnd, planExpiresAt: $planExpiresAt, stripeSubscriptionId: $stripeSubscriptionId, paymentMethod: $paymentMethod, aiGenerationsRemaining: $aiGenerationsRemaining, viewersPerTrip: $viewersPerTrip, offlineNotifications: $offlineNotifications, postVoyageAi: $postVoyageAi)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionDetailsCopyWith<$Res> implements $SubscriptionDetailsCopyWith<$Res> {
  factory _$SubscriptionDetailsCopyWith(_SubscriptionDetails value, $Res Function(_SubscriptionDetails) _then) = __$SubscriptionDetailsCopyWithImpl;
@override @useResult
$Res call({
 String plan,@JsonKey(name: 'cancel_at_period_end') bool cancelAtPeriodEnd,@JsonKey(name: 'current_period_end') DateTime? currentPeriodEnd,@JsonKey(name: 'plan_expires_at') DateTime? planExpiresAt,@JsonKey(name: 'stripe_subscription_id') String? stripeSubscriptionId,@JsonKey(name: 'payment_method') PaymentMethodPreview? paymentMethod,@JsonKey(name: 'ai_generations_remaining') int? aiGenerationsRemaining,@JsonKey(name: 'viewers_per_trip') int? viewersPerTrip,@JsonKey(name: 'offline_notifications') bool? offlineNotifications,@JsonKey(name: 'post_voyage_ai') bool? postVoyageAi
});


@override $PaymentMethodPreviewCopyWith<$Res>? get paymentMethod;

}
/// @nodoc
class __$SubscriptionDetailsCopyWithImpl<$Res>
    implements _$SubscriptionDetailsCopyWith<$Res> {
  __$SubscriptionDetailsCopyWithImpl(this._self, this._then);

  final _SubscriptionDetails _self;
  final $Res Function(_SubscriptionDetails) _then;

/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? cancelAtPeriodEnd = null,Object? currentPeriodEnd = freezed,Object? planExpiresAt = freezed,Object? stripeSubscriptionId = freezed,Object? paymentMethod = freezed,Object? aiGenerationsRemaining = freezed,Object? viewersPerTrip = freezed,Object? offlineNotifications = freezed,Object? postVoyageAi = freezed,}) {
  return _then(_SubscriptionDetails(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,cancelAtPeriodEnd: null == cancelAtPeriodEnd ? _self.cancelAtPeriodEnd : cancelAtPeriodEnd // ignore: cast_nullable_to_non_nullable
as bool,currentPeriodEnd: freezed == currentPeriodEnd ? _self.currentPeriodEnd : currentPeriodEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,planExpiresAt: freezed == planExpiresAt ? _self.planExpiresAt : planExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,stripeSubscriptionId: freezed == stripeSubscriptionId ? _self.stripeSubscriptionId : stripeSubscriptionId // ignore: cast_nullable_to_non_nullable
as String?,paymentMethod: freezed == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethodPreview?,aiGenerationsRemaining: freezed == aiGenerationsRemaining ? _self.aiGenerationsRemaining : aiGenerationsRemaining // ignore: cast_nullable_to_non_nullable
as int?,viewersPerTrip: freezed == viewersPerTrip ? _self.viewersPerTrip : viewersPerTrip // ignore: cast_nullable_to_non_nullable
as int?,offlineNotifications: freezed == offlineNotifications ? _self.offlineNotifications : offlineNotifications // ignore: cast_nullable_to_non_nullable
as bool?,postVoyageAi: freezed == postVoyageAi ? _self.postVoyageAi : postVoyageAi // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of SubscriptionDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentMethodPreviewCopyWith<$Res>? get paymentMethod {
    if (_self.paymentMethod == null) {
    return null;
  }

  return $PaymentMethodPreviewCopyWith<$Res>(_self.paymentMethod!, (value) {
    return _then(_self.copyWith(paymentMethod: value));
  });
}
}

// dart format on
