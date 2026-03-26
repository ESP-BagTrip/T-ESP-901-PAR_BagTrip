// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accommodation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Accommodation {

 String get id; String get tripId; String get name; String? get address; DateTime? get checkIn; DateTime? get checkOut; double? get pricePerNight; String? get currency; String? get bookingReference; String? get notes; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Accommodation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccommodationCopyWith<Accommodation> get copyWith => _$AccommodationCopyWithImpl<Accommodation>(this as Accommodation, _$identity);

  /// Serializes this Accommodation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Accommodation&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.bookingReference, bookingReference) || other.bookingReference == bookingReference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,address,checkIn,checkOut,pricePerNight,currency,bookingReference,notes,createdAt,updatedAt);

@override
String toString() {
  return 'Accommodation(id: $id, tripId: $tripId, name: $name, address: $address, checkIn: $checkIn, checkOut: $checkOut, pricePerNight: $pricePerNight, currency: $currency, bookingReference: $bookingReference, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccommodationCopyWith<$Res>  {
  factory $AccommodationCopyWith(Accommodation value, $Res Function(Accommodation) _then) = _$AccommodationCopyWithImpl;
@useResult
$Res call({
 String id, String tripId, String name, String? address, DateTime? checkIn, DateTime? checkOut, double? pricePerNight, String? currency, String? bookingReference, String? notes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$AccommodationCopyWithImpl<$Res>
    implements $AccommodationCopyWith<$Res> {
  _$AccommodationCopyWithImpl(this._self, this._then);

  final Accommodation _self;
  final $Res Function(Accommodation) _then;

/// Create a copy of Accommodation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? address = freezed,Object? checkIn = freezed,Object? checkOut = freezed,Object? pricePerNight = freezed,Object? currency = freezed,Object? bookingReference = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,pricePerNight: freezed == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,bookingReference: freezed == bookingReference ? _self.bookingReference : bookingReference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Accommodation].
extension AccommodationPatterns on Accommodation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Accommodation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Accommodation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Accommodation value)  $default,){
final _that = this;
switch (_that) {
case _Accommodation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Accommodation value)?  $default,){
final _that = this;
switch (_that) {
case _Accommodation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String? address,  DateTime? checkIn,  DateTime? checkOut,  double? pricePerNight,  String? currency,  String? bookingReference,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Accommodation() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.address,_that.checkIn,_that.checkOut,_that.pricePerNight,_that.currency,_that.bookingReference,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tripId,  String name,  String? address,  DateTime? checkIn,  DateTime? checkOut,  double? pricePerNight,  String? currency,  String? bookingReference,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Accommodation():
return $default(_that.id,_that.tripId,_that.name,_that.address,_that.checkIn,_that.checkOut,_that.pricePerNight,_that.currency,_that.bookingReference,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tripId,  String name,  String? address,  DateTime? checkIn,  DateTime? checkOut,  double? pricePerNight,  String? currency,  String? bookingReference,  String? notes,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Accommodation() when $default != null:
return $default(_that.id,_that.tripId,_that.name,_that.address,_that.checkIn,_that.checkOut,_that.pricePerNight,_that.currency,_that.bookingReference,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Accommodation implements Accommodation {
  const _Accommodation({required this.id, required this.tripId, required this.name, this.address, this.checkIn, this.checkOut, this.pricePerNight, this.currency, this.bookingReference, this.notes, this.createdAt, this.updatedAt});
  factory _Accommodation.fromJson(Map<String, dynamic> json) => _$AccommodationFromJson(json);

@override final  String id;
@override final  String tripId;
@override final  String name;
@override final  String? address;
@override final  DateTime? checkIn;
@override final  DateTime? checkOut;
@override final  double? pricePerNight;
@override final  String? currency;
@override final  String? bookingReference;
@override final  String? notes;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Accommodation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccommodationCopyWith<_Accommodation> get copyWith => __$AccommodationCopyWithImpl<_Accommodation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccommodationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Accommodation&&(identical(other.id, id) || other.id == id)&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.pricePerNight, pricePerNight) || other.pricePerNight == pricePerNight)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.bookingReference, bookingReference) || other.bookingReference == bookingReference)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tripId,name,address,checkIn,checkOut,pricePerNight,currency,bookingReference,notes,createdAt,updatedAt);

@override
String toString() {
  return 'Accommodation(id: $id, tripId: $tripId, name: $name, address: $address, checkIn: $checkIn, checkOut: $checkOut, pricePerNight: $pricePerNight, currency: $currency, bookingReference: $bookingReference, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccommodationCopyWith<$Res> implements $AccommodationCopyWith<$Res> {
  factory _$AccommodationCopyWith(_Accommodation value, $Res Function(_Accommodation) _then) = __$AccommodationCopyWithImpl;
@override @useResult
$Res call({
 String id, String tripId, String name, String? address, DateTime? checkIn, DateTime? checkOut, double? pricePerNight, String? currency, String? bookingReference, String? notes, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$AccommodationCopyWithImpl<$Res>
    implements _$AccommodationCopyWith<$Res> {
  __$AccommodationCopyWithImpl(this._self, this._then);

  final _Accommodation _self;
  final $Res Function(_Accommodation) _then;

/// Create a copy of Accommodation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tripId = null,Object? name = null,Object? address = freezed,Object? checkIn = freezed,Object? checkOut = freezed,Object? pricePerNight = freezed,Object? currency = freezed,Object? bookingReference = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Accommodation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,pricePerNight: freezed == pricePerNight ? _self.pricePerNight : pricePerNight // ignore: cast_nullable_to_non_nullable
as double?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,bookingReference: freezed == bookingReference ? _self.bookingReference : bookingReference // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
