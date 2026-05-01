// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_start_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubscriptionStartParams {

@JsonKey(name: 'subscription_id') String get subscriptionId;@JsonKey(name: 'payment_intent_client_secret') String get paymentIntentClientSecret;@JsonKey(name: 'ephemeral_key') String get ephemeralKey; String get customer;
/// Create a copy of SubscriptionStartParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStartParamsCopyWith<SubscriptionStartParams> get copyWith => _$SubscriptionStartParamsCopyWithImpl<SubscriptionStartParams>(this as SubscriptionStartParams, _$identity);

  /// Serializes this SubscriptionStartParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionStartParams&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.paymentIntentClientSecret, paymentIntentClientSecret) || other.paymentIntentClientSecret == paymentIntentClientSecret)&&(identical(other.ephemeralKey, ephemeralKey) || other.ephemeralKey == ephemeralKey)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subscriptionId,paymentIntentClientSecret,ephemeralKey,customer);

@override
String toString() {
  return 'SubscriptionStartParams(subscriptionId: $subscriptionId, paymentIntentClientSecret: $paymentIntentClientSecret, ephemeralKey: $ephemeralKey, customer: $customer)';
}


}

/// @nodoc
abstract mixin class $SubscriptionStartParamsCopyWith<$Res>  {
  factory $SubscriptionStartParamsCopyWith(SubscriptionStartParams value, $Res Function(SubscriptionStartParams) _then) = _$SubscriptionStartParamsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'subscription_id') String subscriptionId,@JsonKey(name: 'payment_intent_client_secret') String paymentIntentClientSecret,@JsonKey(name: 'ephemeral_key') String ephemeralKey, String customer
});




}
/// @nodoc
class _$SubscriptionStartParamsCopyWithImpl<$Res>
    implements $SubscriptionStartParamsCopyWith<$Res> {
  _$SubscriptionStartParamsCopyWithImpl(this._self, this._then);

  final SubscriptionStartParams _self;
  final $Res Function(SubscriptionStartParams) _then;

/// Create a copy of SubscriptionStartParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subscriptionId = null,Object? paymentIntentClientSecret = null,Object? ephemeralKey = null,Object? customer = null,}) {
  return _then(_self.copyWith(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,paymentIntentClientSecret: null == paymentIntentClientSecret ? _self.paymentIntentClientSecret : paymentIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,ephemeralKey: null == ephemeralKey ? _self.ephemeralKey : ephemeralKey // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionStartParams].
extension SubscriptionStartParamsPatterns on SubscriptionStartParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionStartParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionStartParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionStartParams value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStartParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionStartParams value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStartParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'subscription_id')  String subscriptionId, @JsonKey(name: 'payment_intent_client_secret')  String paymentIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionStartParams() when $default != null:
return $default(_that.subscriptionId,_that.paymentIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'subscription_id')  String subscriptionId, @JsonKey(name: 'payment_intent_client_secret')  String paymentIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStartParams():
return $default(_that.subscriptionId,_that.paymentIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'subscription_id')  String subscriptionId, @JsonKey(name: 'payment_intent_client_secret')  String paymentIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStartParams() when $default != null:
return $default(_that.subscriptionId,_that.paymentIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionStartParams implements SubscriptionStartParams {
  const _SubscriptionStartParams({@JsonKey(name: 'subscription_id') required this.subscriptionId, @JsonKey(name: 'payment_intent_client_secret') required this.paymentIntentClientSecret, @JsonKey(name: 'ephemeral_key') required this.ephemeralKey, required this.customer});
  factory _SubscriptionStartParams.fromJson(Map<String, dynamic> json) => _$SubscriptionStartParamsFromJson(json);

@override@JsonKey(name: 'subscription_id') final  String subscriptionId;
@override@JsonKey(name: 'payment_intent_client_secret') final  String paymentIntentClientSecret;
@override@JsonKey(name: 'ephemeral_key') final  String ephemeralKey;
@override final  String customer;

/// Create a copy of SubscriptionStartParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionStartParamsCopyWith<_SubscriptionStartParams> get copyWith => __$SubscriptionStartParamsCopyWithImpl<_SubscriptionStartParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionStartParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionStartParams&&(identical(other.subscriptionId, subscriptionId) || other.subscriptionId == subscriptionId)&&(identical(other.paymentIntentClientSecret, paymentIntentClientSecret) || other.paymentIntentClientSecret == paymentIntentClientSecret)&&(identical(other.ephemeralKey, ephemeralKey) || other.ephemeralKey == ephemeralKey)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subscriptionId,paymentIntentClientSecret,ephemeralKey,customer);

@override
String toString() {
  return 'SubscriptionStartParams(subscriptionId: $subscriptionId, paymentIntentClientSecret: $paymentIntentClientSecret, ephemeralKey: $ephemeralKey, customer: $customer)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStartParamsCopyWith<$Res> implements $SubscriptionStartParamsCopyWith<$Res> {
  factory _$SubscriptionStartParamsCopyWith(_SubscriptionStartParams value, $Res Function(_SubscriptionStartParams) _then) = __$SubscriptionStartParamsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'subscription_id') String subscriptionId,@JsonKey(name: 'payment_intent_client_secret') String paymentIntentClientSecret,@JsonKey(name: 'ephemeral_key') String ephemeralKey, String customer
});




}
/// @nodoc
class __$SubscriptionStartParamsCopyWithImpl<$Res>
    implements _$SubscriptionStartParamsCopyWith<$Res> {
  __$SubscriptionStartParamsCopyWithImpl(this._self, this._then);

  final _SubscriptionStartParams _self;
  final $Res Function(_SubscriptionStartParams) _then;

/// Create a copy of SubscriptionStartParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subscriptionId = null,Object? paymentIntentClientSecret = null,Object? ephemeralKey = null,Object? customer = null,}) {
  return _then(_SubscriptionStartParams(
subscriptionId: null == subscriptionId ? _self.subscriptionId : subscriptionId // ignore: cast_nullable_to_non_nullable
as String,paymentIntentClientSecret: null == paymentIntentClientSecret ? _self.paymentIntentClientSecret : paymentIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,ephemeralKey: null == ephemeralKey ? _self.ephemeralKey : ephemeralKey // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
