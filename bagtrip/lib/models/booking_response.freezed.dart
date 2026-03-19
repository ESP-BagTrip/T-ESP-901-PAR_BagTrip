// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingResponse {

 String get id;@JsonKey(name: 'amadeusOrderId') String get amadeusOrderId; String get status;@JsonKey(name: 'priceTotal') double get priceTotal; String get currency;@JsonKey(name: 'createdAt') DateTime? get createdAt;
/// Create a copy of BookingResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingResponseCopyWith<BookingResponse> get copyWith => _$BookingResponseCopyWithImpl<BookingResponse>(this as BookingResponse, _$identity);

  /// Serializes this BookingResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.amadeusOrderId, amadeusOrderId) || other.amadeusOrderId == amadeusOrderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.priceTotal, priceTotal) || other.priceTotal == priceTotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amadeusOrderId,status,priceTotal,currency,createdAt);

@override
String toString() {
  return 'BookingResponse(id: $id, amadeusOrderId: $amadeusOrderId, status: $status, priceTotal: $priceTotal, currency: $currency, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BookingResponseCopyWith<$Res>  {
  factory $BookingResponseCopyWith(BookingResponse value, $Res Function(BookingResponse) _then) = _$BookingResponseCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'amadeusOrderId') String amadeusOrderId, String status,@JsonKey(name: 'priceTotal') double priceTotal, String currency,@JsonKey(name: 'createdAt') DateTime? createdAt
});




}
/// @nodoc
class _$BookingResponseCopyWithImpl<$Res>
    implements $BookingResponseCopyWith<$Res> {
  _$BookingResponseCopyWithImpl(this._self, this._then);

  final BookingResponse _self;
  final $Res Function(BookingResponse) _then;

/// Create a copy of BookingResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amadeusOrderId = null,Object? status = null,Object? priceTotal = null,Object? currency = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amadeusOrderId: null == amadeusOrderId ? _self.amadeusOrderId : amadeusOrderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priceTotal: null == priceTotal ? _self.priceTotal : priceTotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingResponse].
extension BookingResponsePatterns on BookingResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingResponse value)  $default,){
final _that = this;
switch (_that) {
case _BookingResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingResponse value)?  $default,){
final _that = this;
switch (_that) {
case _BookingResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'amadeusOrderId')  String amadeusOrderId,  String status, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency, @JsonKey(name: 'createdAt')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingResponse() when $default != null:
return $default(_that.id,_that.amadeusOrderId,_that.status,_that.priceTotal,_that.currency,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'amadeusOrderId')  String amadeusOrderId,  String status, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency, @JsonKey(name: 'createdAt')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _BookingResponse():
return $default(_that.id,_that.amadeusOrderId,_that.status,_that.priceTotal,_that.currency,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'amadeusOrderId')  String amadeusOrderId,  String status, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency, @JsonKey(name: 'createdAt')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingResponse() when $default != null:
return $default(_that.id,_that.amadeusOrderId,_that.status,_that.priceTotal,_that.currency,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingResponse implements BookingResponse {
  const _BookingResponse({required this.id, @JsonKey(name: 'amadeusOrderId') required this.amadeusOrderId, required this.status, @JsonKey(name: 'priceTotal') required this.priceTotal, required this.currency, @JsonKey(name: 'createdAt') this.createdAt});
  factory _BookingResponse.fromJson(Map<String, dynamic> json) => _$BookingResponseFromJson(json);

@override final  String id;
@override@JsonKey(name: 'amadeusOrderId') final  String amadeusOrderId;
@override final  String status;
@override@JsonKey(name: 'priceTotal') final  double priceTotal;
@override final  String currency;
@override@JsonKey(name: 'createdAt') final  DateTime? createdAt;

/// Create a copy of BookingResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingResponseCopyWith<_BookingResponse> get copyWith => __$BookingResponseCopyWithImpl<_BookingResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.amadeusOrderId, amadeusOrderId) || other.amadeusOrderId == amadeusOrderId)&&(identical(other.status, status) || other.status == status)&&(identical(other.priceTotal, priceTotal) || other.priceTotal == priceTotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amadeusOrderId,status,priceTotal,currency,createdAt);

@override
String toString() {
  return 'BookingResponse(id: $id, amadeusOrderId: $amadeusOrderId, status: $status, priceTotal: $priceTotal, currency: $currency, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BookingResponseCopyWith<$Res> implements $BookingResponseCopyWith<$Res> {
  factory _$BookingResponseCopyWith(_BookingResponse value, $Res Function(_BookingResponse) _then) = __$BookingResponseCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'amadeusOrderId') String amadeusOrderId, String status,@JsonKey(name: 'priceTotal') double priceTotal, String currency,@JsonKey(name: 'createdAt') DateTime? createdAt
});




}
/// @nodoc
class __$BookingResponseCopyWithImpl<$Res>
    implements _$BookingResponseCopyWith<$Res> {
  __$BookingResponseCopyWithImpl(this._self, this._then);

  final _BookingResponse _self;
  final $Res Function(_BookingResponse) _then;

/// Create a copy of BookingResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amadeusOrderId = null,Object? status = null,Object? priceTotal = null,Object? currency = null,Object? createdAt = freezed,}) {
  return _then(_BookingResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amadeusOrderId: null == amadeusOrderId ? _self.amadeusOrderId : amadeusOrderId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priceTotal: null == priceTotal ? _self.priceTotal : priceTotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
