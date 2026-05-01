// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_method_setup_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentMethodSetupParams {

@JsonKey(name: 'setup_intent_client_secret') String get setupIntentClientSecret;@JsonKey(name: 'ephemeral_key') String get ephemeralKey; String get customer;
/// Create a copy of PaymentMethodSetupParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodSetupParamsCopyWith<PaymentMethodSetupParams> get copyWith => _$PaymentMethodSetupParamsCopyWithImpl<PaymentMethodSetupParams>(this as PaymentMethodSetupParams, _$identity);

  /// Serializes this PaymentMethodSetupParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethodSetupParams&&(identical(other.setupIntentClientSecret, setupIntentClientSecret) || other.setupIntentClientSecret == setupIntentClientSecret)&&(identical(other.ephemeralKey, ephemeralKey) || other.ephemeralKey == ephemeralKey)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setupIntentClientSecret,ephemeralKey,customer);

@override
String toString() {
  return 'PaymentMethodSetupParams(setupIntentClientSecret: $setupIntentClientSecret, ephemeralKey: $ephemeralKey, customer: $customer)';
}


}

/// @nodoc
abstract mixin class $PaymentMethodSetupParamsCopyWith<$Res>  {
  factory $PaymentMethodSetupParamsCopyWith(PaymentMethodSetupParams value, $Res Function(PaymentMethodSetupParams) _then) = _$PaymentMethodSetupParamsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'setup_intent_client_secret') String setupIntentClientSecret,@JsonKey(name: 'ephemeral_key') String ephemeralKey, String customer
});




}
/// @nodoc
class _$PaymentMethodSetupParamsCopyWithImpl<$Res>
    implements $PaymentMethodSetupParamsCopyWith<$Res> {
  _$PaymentMethodSetupParamsCopyWithImpl(this._self, this._then);

  final PaymentMethodSetupParams _self;
  final $Res Function(PaymentMethodSetupParams) _then;

/// Create a copy of PaymentMethodSetupParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setupIntentClientSecret = null,Object? ephemeralKey = null,Object? customer = null,}) {
  return _then(_self.copyWith(
setupIntentClientSecret: null == setupIntentClientSecret ? _self.setupIntentClientSecret : setupIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,ephemeralKey: null == ephemeralKey ? _self.ephemeralKey : ephemeralKey // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentMethodSetupParams].
extension PaymentMethodSetupParamsPatterns on PaymentMethodSetupParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethodSetupParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethodSetupParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethodSetupParams value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodSetupParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethodSetupParams value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethodSetupParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'setup_intent_client_secret')  String setupIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethodSetupParams() when $default != null:
return $default(_that.setupIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'setup_intent_client_secret')  String setupIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodSetupParams():
return $default(_that.setupIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'setup_intent_client_secret')  String setupIntentClientSecret, @JsonKey(name: 'ephemeral_key')  String ephemeralKey,  String customer)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethodSetupParams() when $default != null:
return $default(_that.setupIntentClientSecret,_that.ephemeralKey,_that.customer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentMethodSetupParams implements PaymentMethodSetupParams {
  const _PaymentMethodSetupParams({@JsonKey(name: 'setup_intent_client_secret') required this.setupIntentClientSecret, @JsonKey(name: 'ephemeral_key') required this.ephemeralKey, required this.customer});
  factory _PaymentMethodSetupParams.fromJson(Map<String, dynamic> json) => _$PaymentMethodSetupParamsFromJson(json);

@override@JsonKey(name: 'setup_intent_client_secret') final  String setupIntentClientSecret;
@override@JsonKey(name: 'ephemeral_key') final  String ephemeralKey;
@override final  String customer;

/// Create a copy of PaymentMethodSetupParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodSetupParamsCopyWith<_PaymentMethodSetupParams> get copyWith => __$PaymentMethodSetupParamsCopyWithImpl<_PaymentMethodSetupParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentMethodSetupParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethodSetupParams&&(identical(other.setupIntentClientSecret, setupIntentClientSecret) || other.setupIntentClientSecret == setupIntentClientSecret)&&(identical(other.ephemeralKey, ephemeralKey) || other.ephemeralKey == ephemeralKey)&&(identical(other.customer, customer) || other.customer == customer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setupIntentClientSecret,ephemeralKey,customer);

@override
String toString() {
  return 'PaymentMethodSetupParams(setupIntentClientSecret: $setupIntentClientSecret, ephemeralKey: $ephemeralKey, customer: $customer)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodSetupParamsCopyWith<$Res> implements $PaymentMethodSetupParamsCopyWith<$Res> {
  factory _$PaymentMethodSetupParamsCopyWith(_PaymentMethodSetupParams value, $Res Function(_PaymentMethodSetupParams) _then) = __$PaymentMethodSetupParamsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'setup_intent_client_secret') String setupIntentClientSecret,@JsonKey(name: 'ephemeral_key') String ephemeralKey, String customer
});




}
/// @nodoc
class __$PaymentMethodSetupParamsCopyWithImpl<$Res>
    implements _$PaymentMethodSetupParamsCopyWith<$Res> {
  __$PaymentMethodSetupParamsCopyWithImpl(this._self, this._then);

  final _PaymentMethodSetupParams _self;
  final $Res Function(_PaymentMethodSetupParams) _then;

/// Create a copy of PaymentMethodSetupParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setupIntentClientSecret = null,Object? ephemeralKey = null,Object? customer = null,}) {
  return _then(_PaymentMethodSetupParams(
setupIntentClientSecret: null == setupIntentClientSecret ? _self.setupIntentClientSecret : setupIntentClientSecret // ignore: cast_nullable_to_non_nullable
as String,ephemeralKey: null == ephemeralKey ? _self.ephemeralKey : ephemeralKey // ignore: cast_nullable_to_non_nullable
as String,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
