// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manual_flight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManualFlight {

 String get id; String get tripId; String get flightNumber; String? get airline; String? get departureAirport; String? get arrivalAirport; DateTime? get departureDate; DateTime? get arrivalDate; double? get price; String? get currency; String? get notes; String get flightType; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of ManualFlight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManualFlightCopyWith<ManualFlight> get copyWith => _$ManualFlightCopyWithImpl<ManualFlight>(this as ManualFlight, _$identity);

  /// Serializes this ManualFlight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualFlight&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.flightNumber, flightNumber) || other.flightNumber == flightNumber)&&(identical(other.airline, airline) || other.airline == airline)&&(identical(other.departureAirport, departureAirport) || other.departureAirport == departureAirport)&&(identical(other.arrivalAirport, arrivalAirport) || other.arrivalAirport == arrivalAirport)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate)&&(identical(other.arrivalDate, arrivalDate) || other.arrivalDate == arrivalDate)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.flightType, flightType) || other.flightType == flightType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,flightNumber,airline,departureAirport,arrivalAirport,departureDate,arrivalDate,price,currency,notes,flightType,createdAt,updatedAt);

@override
String toString() {
  return 'ManualFlight(id: $id, tripId: $tripId, flightNumber: $flightNumber, airline: $airline, departureAirport: $departureAirport, arrivalAirport: $arrivalAirport, departureDate: $departureDate, arrivalDate: $arrivalDate, price: $price, currency: $currency, notes: $notes, flightType: $flightType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ManualFlightCopyWith<$Res>  {
  factory $ManualFlightCopyWith(ManualFlight value, $Res Function(ManualFlight) _then) = _$ManualFlightCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String flightNumber, String? airline, String? departureAirport, String? arrivalAirport, DateTime? departureDate, DateTime? arrivalDate, double? price, String? currency, String? notes, String flightType, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ManualFlightCopyWithImpl<$Res>
    implements $ManualFlightCopyWith<$Res> {
  _$ManualFlightCopyWithImpl(this._self, this._then);

  final ManualFlight _self;
  final $Res Function(ManualFlight) _then;

/// Create a copy of ManualFlight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? flightNumber = null,Object? airline = freezed,Object? departureAirport = freezed,Object? arrivalAirport = freezed,Object? departureDate = freezed,Object? arrivalDate = freezed,Object? price = freezed,Object? currency = freezed,Object? notes = freezed,Object? flightType = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,flightNumber: null == flightNumber ? _self.flightNumber : flightNumber // ignore: cast_nullable_to_non_nullable
as String,airline: freezed == airline ? _self.airline : airline // ignore: cast_nullable_to_non_nullable
as String?,departureAirport: freezed == departureAirport ? _self.departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as String?,arrivalAirport: freezed == arrivalAirport ? _self.arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as String?,departureDate: freezed == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivalDate: freezed == arrivalDate ? _self.arrivalDate : arrivalDate // ignore: cast_nullable_to_non_nullable
as DateTime?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,flightType: null == flightType ? _self.flightType : flightType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ManualFlight].
extension ManualFlightPatterns on ManualFlight {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManualFlight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManualFlight() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManualFlight value)  $default,){
final _that = this;
switch (_that) {
case _ManualFlight():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManualFlight value)?  $default,){
final _that = this;
switch (_that) {
case _ManualFlight() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String flightNumber,  String? airline,  String? departureAirport,  String? arrivalAirport,  DateTime? departureDate,  DateTime? arrivalDate,  double? price,  String? currency,  String? notes,  String flightType,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManualFlight() when $default != null:
return $default(_that.id,_that.tripId,_that.flightNumber,_that.airline,_that.departureAirport,_that.arrivalAirport,_that.departureDate,_that.arrivalDate,_that.price,_that.currency,_that.notes,_that.flightType,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String flightNumber,  String? airline,  String? departureAirport,  String? arrivalAirport,  DateTime? departureDate,  DateTime? arrivalDate,  double? price,  String? currency,  String? notes,  String flightType,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ManualFlight():
return $default(_that.id,_that.tripId,_that.flightNumber,_that.airline,_that.departureAirport,_that.arrivalAirport,_that.departureDate,_that.arrivalDate,_that.price,_that.currency,_that.notes,_that.flightType,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String flightNumber,  String? airline,  String? departureAirport,  String? arrivalAirport,  DateTime? departureDate,  DateTime? arrivalDate,  double? price,  String? currency,  String? notes,  String flightType,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ManualFlight() when $default != null:
return $default(_that.id,_that.tripId,_that.flightNumber,_that.airline,_that.departureAirport,_that.arrivalAirport,_that.departureDate,_that.arrivalDate,_that.price,_that.currency,_that.notes,_that.flightType,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ManualFlight implements ManualFlight {
  const _ManualFlight({required this.id, required this.tripId, required this.flightNumber, this.airline, this.departureAirport, this.arrivalAirport, this.departureDate, this.arrivalDate, this.price, this.currency, this.notes, this.flightType = 'MAIN', this.createdAt, this.updatedAt});
  factory _ManualFlight.fromJson(Map<String, dynamic> json) => _$ManualFlightFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String flightNumber;
@override final  String? airline;
@override final  String? departureAirport;
@override final  String? arrivalAirport;
@override final  DateTime? departureDate;
@override final  DateTime? arrivalDate;
@override final  double? price;
@override final  String? currency;
@override final  String? notes;
@override@JsonKey() final  String flightType;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of ManualFlight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManualFlightCopyWith<_ManualFlight> get copyWith => __$ManualFlightCopyWithImpl<_ManualFlight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManualFlightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManualFlight&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.flightNumber, flightNumber) || other.flightNumber == flightNumber)&&(identical(other.airline, airline) || other.airline == airline)&&(identical(other.departureAirport, departureAirport) || other.departureAirport == departureAirport)&&(identical(other.arrivalAirport, arrivalAirport) || other.arrivalAirport == arrivalAirport)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate)&&(identical(other.arrivalDate, arrivalDate) || other.arrivalDate == arrivalDate)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.flightType, flightType) || other.flightType == flightType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,flightNumber,airline,departureAirport,arrivalAirport,departureDate,arrivalDate,price,currency,notes,flightType,createdAt,updatedAt);

@override
String toString() {
  return 'ManualFlight(id: $id, tripId: $tripId, flightNumber: $flightNumber, airline: $airline, departureAirport: $departureAirport, arrivalAirport: $arrivalAirport, departureDate: $departureDate, arrivalDate: $arrivalDate, price: $price, currency: $currency, notes: $notes, flightType: $flightType, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ManualFlightCopyWith<$Res> implements $ManualFlightCopyWith<$Res> {
  factory _$ManualFlightCopyWith(_ManualFlight value, $Res Function(_ManualFlight) _then) = __$ManualFlightCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String flightNumber, String? airline, String? departureAirport, String? arrivalAirport, DateTime? departureDate, DateTime? arrivalDate, double? price, String? currency, String? notes, String flightType, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ManualFlightCopyWithImpl<$Res>
    implements _$ManualFlightCopyWith<$Res> {
  __$ManualFlightCopyWithImpl(this._self, this._then);

  final _ManualFlight _self;
  final $Res Function(_ManualFlight) _then;

/// Create a copy of ManualFlight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? flightNumber = null,Object? airline = freezed,Object? departureAirport = freezed,Object? arrivalAirport = freezed,Object? departureDate = freezed,Object? arrivalDate = freezed,Object? price = freezed,Object? currency = freezed,Object? notes = freezed,Object? flightType = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ManualFlight(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,flightNumber: null == flightNumber ? _self.flightNumber : flightNumber // ignore: cast_nullable_to_non_nullable
as String,airline: freezed == airline ? _self.airline : airline // ignore: cast_nullable_to_non_nullable
as String?,departureAirport: freezed == departureAirport ? _self.departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as String?,arrivalAirport: freezed == arrivalAirport ? _self.arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as String?,departureDate: freezed == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivalDate: freezed == arrivalDate ? _self.arrivalDate : arrivalDate // ignore: cast_nullable_to_non_nullable
as DateTime?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,flightType: null == flightType ? _self.flightType : flightType // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
