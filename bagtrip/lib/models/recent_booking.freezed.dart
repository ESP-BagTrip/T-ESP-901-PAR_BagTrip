// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecentBooking {

 String get id; String get details; DateTime get date;@JsonKey(name: 'priceTotal') double get priceTotal; String get currency; String get status;
/// Create a copy of RecentBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentBookingCopyWith<RecentBooking> get copyWith => _$RecentBookingCopyWithImpl<RecentBooking>(this as RecentBooking, _$identity);

  /// Serializes this RecentBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.details, details) || other.details == details)&&(identical(other.date, date) || other.date == date)&&(identical(other.priceTotal, priceTotal) || other.priceTotal == priceTotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,details,date,priceTotal,currency,status);

@override
String toString() {
  return 'RecentBooking(id: $id, details: $details, date: $date, priceTotal: $priceTotal, currency: $currency, status: $status)';
}


}

/// @nodoc
abstract mixin class $RecentBookingCopyWith<$Res>  {
  factory $RecentBookingCopyWith(RecentBooking value, $Res Function(RecentBooking) _then) = _$RecentBookingCopyWithImpl;
@useResult
$Res call({
 String id, String details, DateTime date,@JsonKey(name: 'priceTotal') double priceTotal, String currency, String status
});




}
/// @nodoc
class _$RecentBookingCopyWithImpl<$Res>
    implements $RecentBookingCopyWith<$Res> {
  _$RecentBookingCopyWithImpl(this._self, this._then);

  final RecentBooking _self;
  final $Res Function(RecentBooking) _then;

/// Create a copy of RecentBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? details = null,Object? date = null,Object? priceTotal = null,Object? currency = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,priceTotal: null == priceTotal ? _self.priceTotal : priceTotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentBooking].
extension RecentBookingPatterns on RecentBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentBooking value)  $default,){
final _that = this;
switch (_that) {
case _RecentBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentBooking value)?  $default,){
final _that = this;
switch (_that) {
case _RecentBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String details,  DateTime date, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentBooking() when $default != null:
return $default(_that.id,_that.details,_that.date,_that.priceTotal,_that.currency,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String details,  DateTime date, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency,  String status)  $default,) {final _that = this;
switch (_that) {
case _RecentBooking():
return $default(_that.id,_that.details,_that.date,_that.priceTotal,_that.currency,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String details,  DateTime date, @JsonKey(name: 'priceTotal')  double priceTotal,  String currency,  String status)?  $default,) {final _that = this;
switch (_that) {
case _RecentBooking() when $default != null:
return $default(_that.id,_that.details,_that.date,_that.priceTotal,_that.currency,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentBooking implements RecentBooking {
  const _RecentBooking({required this.id, required this.details, required this.date, @JsonKey(name: 'priceTotal') required this.priceTotal, required this.currency, required this.status});
  factory _RecentBooking.fromJson(Map<String, dynamic> json) => _$RecentBookingFromJson(json);

@override final  String id;
@override final  String details;
@override final  DateTime date;
@override@JsonKey(name: 'priceTotal') final  double priceTotal;
@override final  String currency;
@override final  String status;

/// Create a copy of RecentBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentBookingCopyWith<_RecentBooking> get copyWith => __$RecentBookingCopyWithImpl<_RecentBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentBookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.details, details) || other.details == details)&&(identical(other.date, date) || other.date == date)&&(identical(other.priceTotal, priceTotal) || other.priceTotal == priceTotal)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,details,date,priceTotal,currency,status);

@override
String toString() {
  return 'RecentBooking(id: $id, details: $details, date: $date, priceTotal: $priceTotal, currency: $currency, status: $status)';
}


}

/// @nodoc
abstract mixin class _$RecentBookingCopyWith<$Res> implements $RecentBookingCopyWith<$Res> {
  factory _$RecentBookingCopyWith(_RecentBooking value, $Res Function(_RecentBooking) _then) = __$RecentBookingCopyWithImpl;
@override @useResult
$Res call({
 String id, String details, DateTime date,@JsonKey(name: 'priceTotal') double priceTotal, String currency, String status
});




}
/// @nodoc
class __$RecentBookingCopyWithImpl<$Res>
    implements _$RecentBookingCopyWith<$Res> {
  __$RecentBookingCopyWithImpl(this._self, this._then);

  final _RecentBooking _self;
  final $Res Function(_RecentBooking) _then;

/// Create a copy of RecentBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? details = null,Object? date = null,Object? priceTotal = null,Object? currency = null,Object? status = null,}) {
  return _then(_RecentBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,details: null == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,priceTotal: null == priceTotal ? _self.priceTotal : priceTotal // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
