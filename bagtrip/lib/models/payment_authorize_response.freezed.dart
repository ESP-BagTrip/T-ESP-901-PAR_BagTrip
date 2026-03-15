// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_authorize_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentAuthorizeResponse {

 String get stripePaymentIntentId; String get clientSecret; String get status;
/// Create a copy of PaymentAuthorizeResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentAuthorizeResponseCopyWith<PaymentAuthorizeResponse> get copyWith => _$PaymentAuthorizeResponseCopyWithImpl<PaymentAuthorizeResponse>(this as PaymentAuthorizeResponse, _$identity);

  /// Serializes this PaymentAuthorizeResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentAuthorizeResponse&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stripePaymentIntentId,clientSecret,status);

@override
String toString() {
  return 'PaymentAuthorizeResponse(stripePaymentIntentId: $stripePaymentIntentId, clientSecret: $clientSecret, status: $status)';
}


}

/// @nodoc
abstract mixin class $PaymentAuthorizeResponseCopyWith<$Res>  {
  factory $PaymentAuthorizeResponseCopyWith(PaymentAuthorizeResponse value, $Res Function(PaymentAuthorizeResponse) _then) = _$PaymentAuthorizeResponseCopyWithImpl;
@useResult
$Res call({
 String stripePaymentIntentId, String clientSecret, String status
});




}
/// @nodoc
class _$PaymentAuthorizeResponseCopyWithImpl<$Res>
    implements $PaymentAuthorizeResponseCopyWith<$Res> {
  _$PaymentAuthorizeResponseCopyWithImpl(this._self, this._then);

  final PaymentAuthorizeResponse _self;
  final $Res Function(PaymentAuthorizeResponse) _then;

/// Create a copy of PaymentAuthorizeResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stripePaymentIntentId = null,Object? clientSecret = null,Object? status = null,}) {
  return _then(_self.copyWith(
stripePaymentIntentId: null == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String,clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentAuthorizeResponse].
extension PaymentAuthorizeResponsePatterns on PaymentAuthorizeResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentAuthorizeResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentAuthorizeResponse value)  $default,){
final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentAuthorizeResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stripePaymentIntentId,  String clientSecret,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse() when $default != null:
return $default(_that.stripePaymentIntentId,_that.clientSecret,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stripePaymentIntentId,  String clientSecret,  String status)  $default,) {final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse():
return $default(_that.stripePaymentIntentId,_that.clientSecret,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stripePaymentIntentId,  String clientSecret,  String status)?  $default,) {final _that = this;
switch (_that) {
case _PaymentAuthorizeResponse() when $default != null:
return $default(_that.stripePaymentIntentId,_that.clientSecret,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentAuthorizeResponse implements PaymentAuthorizeResponse {
  const _PaymentAuthorizeResponse({required this.stripePaymentIntentId, required this.clientSecret, required this.status});
  factory _PaymentAuthorizeResponse.fromJson(Map<String, dynamic> json) => _$PaymentAuthorizeResponseFromJson(json);

@override final  String stripePaymentIntentId;
@override final  String clientSecret;
@override final  String status;

/// Create a copy of PaymentAuthorizeResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentAuthorizeResponseCopyWith<_PaymentAuthorizeResponse> get copyWith => __$PaymentAuthorizeResponseCopyWithImpl<_PaymentAuthorizeResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentAuthorizeResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentAuthorizeResponse&&(identical(other.stripePaymentIntentId, stripePaymentIntentId) || other.stripePaymentIntentId == stripePaymentIntentId)&&(identical(other.clientSecret, clientSecret) || other.clientSecret == clientSecret)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stripePaymentIntentId,clientSecret,status);

@override
String toString() {
  return 'PaymentAuthorizeResponse(stripePaymentIntentId: $stripePaymentIntentId, clientSecret: $clientSecret, status: $status)';
}


}

/// @nodoc
abstract mixin class _$PaymentAuthorizeResponseCopyWith<$Res> implements $PaymentAuthorizeResponseCopyWith<$Res> {
  factory _$PaymentAuthorizeResponseCopyWith(_PaymentAuthorizeResponse value, $Res Function(_PaymentAuthorizeResponse) _then) = __$PaymentAuthorizeResponseCopyWithImpl;
@override @useResult
$Res call({
 String stripePaymentIntentId, String clientSecret, String status
});




}
/// @nodoc
class __$PaymentAuthorizeResponseCopyWithImpl<$Res>
    implements _$PaymentAuthorizeResponseCopyWith<$Res> {
  __$PaymentAuthorizeResponseCopyWithImpl(this._self, this._then);

  final _PaymentAuthorizeResponse _self;
  final $Res Function(_PaymentAuthorizeResponse) _then;

/// Create a copy of PaymentAuthorizeResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stripePaymentIntentId = null,Object? clientSecret = null,Object? status = null,}) {
  return _then(_PaymentAuthorizeResponse(
stripePaymentIntentId: null == stripePaymentIntentId ? _self.stripePaymentIntentId : stripePaymentIntentId // ignore: cast_nullable_to_non_nullable
as String,clientSecret: null == clientSecret ? _self.clientSecret : clientSecret // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
