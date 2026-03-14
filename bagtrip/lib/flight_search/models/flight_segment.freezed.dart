// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FlightSegment {

 Map<String, dynamic>? get departureAirport; Map<String, dynamic>? get arrivalAirport; DateTime? get departureDate;
/// Create a copy of FlightSegment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightSegmentCopyWith<FlightSegment> get copyWith => _$FlightSegmentCopyWithImpl<FlightSegment>(this as FlightSegment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightSegment&&const DeepCollectionEquality().equals(other.departureAirport, departureAirport)&&const DeepCollectionEquality().equals(other.arrivalAirport, arrivalAirport)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(departureAirport),const DeepCollectionEquality().hash(arrivalAirport),departureDate);

@override
String toString() {
  return 'FlightSegment(departureAirport: $departureAirport, arrivalAirport: $arrivalAirport, departureDate: $departureDate)';
}


}

/// @nodoc
abstract mixin class $FlightSegmentCopyWith<$Res>  {
  factory $FlightSegmentCopyWith(FlightSegment value, $Res Function(FlightSegment) _then) = _$FlightSegmentCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic>? departureAirport, Map<String, dynamic>? arrivalAirport, DateTime? departureDate
});




}
/// @nodoc
class _$FlightSegmentCopyWithImpl<$Res>
    implements $FlightSegmentCopyWith<$Res> {
  _$FlightSegmentCopyWithImpl(this._self, this._then);

  final FlightSegment _self;
  final $Res Function(FlightSegment) _then;

/// Create a copy of FlightSegment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? departureAirport = freezed,Object? arrivalAirport = freezed,Object? departureDate = freezed,}) {
  return _then(_self.copyWith(
departureAirport: freezed == departureAirport ? _self.departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,arrivalAirport: freezed == arrivalAirport ? _self.arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,departureDate: freezed == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightSegment].
extension FlightSegmentPatterns on FlightSegment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightSegment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightSegment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightSegment value)  $default,){
final _that = this;
switch (_that) {
case _FlightSegment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightSegment value)?  $default,){
final _that = this;
switch (_that) {
case _FlightSegment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, dynamic>? departureAirport,  Map<String, dynamic>? arrivalAirport,  DateTime? departureDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightSegment() when $default != null:
return $default(_that.departureAirport,_that.arrivalAirport,_that.departureDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, dynamic>? departureAirport,  Map<String, dynamic>? arrivalAirport,  DateTime? departureDate)  $default,) {final _that = this;
switch (_that) {
case _FlightSegment():
return $default(_that.departureAirport,_that.arrivalAirport,_that.departureDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, dynamic>? departureAirport,  Map<String, dynamic>? arrivalAirport,  DateTime? departureDate)?  $default,) {final _that = this;
switch (_that) {
case _FlightSegment() when $default != null:
return $default(_that.departureAirport,_that.arrivalAirport,_that.departureDate);case _:
  return null;

}
}

}

/// @nodoc


class _FlightSegment implements FlightSegment {
  const _FlightSegment({final  Map<String, dynamic>? departureAirport, final  Map<String, dynamic>? arrivalAirport, this.departureDate}): _departureAirport = departureAirport,_arrivalAirport = arrivalAirport;
  

 final  Map<String, dynamic>? _departureAirport;
@override Map<String, dynamic>? get departureAirport {
  final value = _departureAirport;
  if (value == null) return null;
  if (_departureAirport is EqualUnmodifiableMapView) return _departureAirport;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _arrivalAirport;
@override Map<String, dynamic>? get arrivalAirport {
  final value = _arrivalAirport;
  if (value == null) return null;
  if (_arrivalAirport is EqualUnmodifiableMapView) return _arrivalAirport;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime? departureDate;

/// Create a copy of FlightSegment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightSegmentCopyWith<_FlightSegment> get copyWith => __$FlightSegmentCopyWithImpl<_FlightSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightSegment&&const DeepCollectionEquality().equals(other._departureAirport, _departureAirport)&&const DeepCollectionEquality().equals(other._arrivalAirport, _arrivalAirport)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_departureAirport),const DeepCollectionEquality().hash(_arrivalAirport),departureDate);

@override
String toString() {
  return 'FlightSegment(departureAirport: $departureAirport, arrivalAirport: $arrivalAirport, departureDate: $departureDate)';
}


}

/// @nodoc
abstract mixin class _$FlightSegmentCopyWith<$Res> implements $FlightSegmentCopyWith<$Res> {
  factory _$FlightSegmentCopyWith(_FlightSegment value, $Res Function(_FlightSegment) _then) = __$FlightSegmentCopyWithImpl;
@override @useResult
$Res call({
 Map<String, dynamic>? departureAirport, Map<String, dynamic>? arrivalAirport, DateTime? departureDate
});




}
/// @nodoc
class __$FlightSegmentCopyWithImpl<$Res>
    implements _$FlightSegmentCopyWith<$Res> {
  __$FlightSegmentCopyWithImpl(this._self, this._then);

  final _FlightSegment _self;
  final $Res Function(_FlightSegment) _then;

/// Create a copy of FlightSegment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? departureAirport = freezed,Object? arrivalAirport = freezed,Object? departureDate = freezed,}) {
  return _then(_FlightSegment(
departureAirport: freezed == departureAirport ? _self._departureAirport : departureAirport // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,arrivalAirport: freezed == arrivalAirport ? _self._arrivalAirport : arrivalAirport // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,departureDate: freezed == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
