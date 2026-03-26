// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_search_arguments.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FlightSearchArguments {

 String get departureCode; String get arrivalCode; DateTime get departureDate; DateTime? get returnDate; int get adults; int get children; int get infants; String get travelClass; List<FlightSegment>? get multiDestSegments; double? get maxPrice;
/// Create a copy of FlightSearchArguments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightSearchArgumentsCopyWith<FlightSearchArguments> get copyWith => _$FlightSearchArgumentsCopyWithImpl<FlightSearchArguments>(this as FlightSearchArguments, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightSearchArguments&&(identical(other.departureCode, departureCode) || other.departureCode == departureCode)&&(identical(other.arrivalCode, arrivalCode) || other.arrivalCode == arrivalCode)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate)&&(identical(other.returnDate, returnDate) || other.returnDate == returnDate)&&(identical(other.adults, adults) || other.adults == adults)&&(identical(other.children, children) || other.children == children)&&(identical(other.infants, infants) || other.infants == infants)&&(identical(other.travelClass, travelClass) || other.travelClass == travelClass)&&const DeepCollectionEquality().equals(other.multiDestSegments, multiDestSegments)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,departureCode,arrivalCode,departureDate,returnDate,adults,children,infants,travelClass,const DeepCollectionEquality().hash(multiDestSegments),maxPrice);

@override
String toString() {
  return 'FlightSearchArguments(departureCode: $departureCode, arrivalCode: $arrivalCode, departureDate: $departureDate, returnDate: $returnDate, adults: $adults, children: $children, infants: $infants, travelClass: $travelClass, multiDestSegments: $multiDestSegments, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class $FlightSearchArgumentsCopyWith<$Res>  {
  factory $FlightSearchArgumentsCopyWith(FlightSearchArguments value, $Res Function(FlightSearchArguments) _then) = _$FlightSearchArgumentsCopyWithImpl;
@useResult
$Res call({
 String departureCode, String arrivalCode, DateTime departureDate, DateTime? returnDate, int adults, int children, int infants, String travelClass, List<FlightSegment>? multiDestSegments, double? maxPrice
});




}
/// @nodoc
class _$FlightSearchArgumentsCopyWithImpl<$Res>
    implements $FlightSearchArgumentsCopyWith<$Res> {
  _$FlightSearchArgumentsCopyWithImpl(this._self, this._then);

  final FlightSearchArguments _self;
  final $Res Function(FlightSearchArguments) _then;

/// Create a copy of FlightSearchArguments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? departureCode = null,Object? arrivalCode = null,Object? departureDate = null,Object? returnDate = freezed,Object? adults = null,Object? children = null,Object? infants = null,Object? travelClass = null,Object? multiDestSegments = freezed,Object? maxPrice = freezed,}) {
  return _then(_self.copyWith(
departureCode: null == departureCode ? _self.departureCode : departureCode // ignore: cast_nullable_to_non_nullable
as String,arrivalCode: null == arrivalCode ? _self.arrivalCode : arrivalCode // ignore: cast_nullable_to_non_nullable
as String,departureDate: null == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime,returnDate: freezed == returnDate ? _self.returnDate : returnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,adults: null == adults ? _self.adults : adults // ignore: cast_nullable_to_non_nullable
as int,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as int,infants: null == infants ? _self.infants : infants // ignore: cast_nullable_to_non_nullable
as int,travelClass: null == travelClass ? _self.travelClass : travelClass // ignore: cast_nullable_to_non_nullable
as String,multiDestSegments: freezed == multiDestSegments ? _self.multiDestSegments : multiDestSegments // ignore: cast_nullable_to_non_nullable
as List<FlightSegment>?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightSearchArguments].
extension FlightSearchArgumentsPatterns on FlightSearchArguments {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightSearchArguments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightSearchArguments() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightSearchArguments value)  $default,){
final _that = this;
switch (_that) {
case _FlightSearchArguments():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightSearchArguments value)?  $default,){
final _that = this;
switch (_that) {
case _FlightSearchArguments() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String departureCode,  String arrivalCode,  DateTime departureDate,  DateTime? returnDate,  int adults,  int children,  int infants,  String travelClass,  List<FlightSegment>? multiDestSegments,  double? maxPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightSearchArguments() when $default != null:
return $default(_that.departureCode,_that.arrivalCode,_that.departureDate,_that.returnDate,_that.adults,_that.children,_that.infants,_that.travelClass,_that.multiDestSegments,_that.maxPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String departureCode,  String arrivalCode,  DateTime departureDate,  DateTime? returnDate,  int adults,  int children,  int infants,  String travelClass,  List<FlightSegment>? multiDestSegments,  double? maxPrice)  $default,) {final _that = this;
switch (_that) {
case _FlightSearchArguments():
return $default(_that.departureCode,_that.arrivalCode,_that.departureDate,_that.returnDate,_that.adults,_that.children,_that.infants,_that.travelClass,_that.multiDestSegments,_that.maxPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String departureCode,  String arrivalCode,  DateTime departureDate,  DateTime? returnDate,  int adults,  int children,  int infants,  String travelClass,  List<FlightSegment>? multiDestSegments,  double? maxPrice)?  $default,) {final _that = this;
switch (_that) {
case _FlightSearchArguments() when $default != null:
return $default(_that.departureCode,_that.arrivalCode,_that.departureDate,_that.returnDate,_that.adults,_that.children,_that.infants,_that.travelClass,_that.multiDestSegments,_that.maxPrice);case _:
  return null;

}
}

}

/// @nodoc


class _FlightSearchArguments implements FlightSearchArguments {
  const _FlightSearchArguments({required this.departureCode, required this.arrivalCode, required this.departureDate, this.returnDate, required this.adults, required this.children, required this.infants, required this.travelClass, final  List<FlightSegment>? multiDestSegments, this.maxPrice}): _multiDestSegments = multiDestSegments;
  

@override final  String departureCode;
@override final  String arrivalCode;
@override final  DateTime departureDate;
@override final  DateTime? returnDate;
@override final  int adults;
@override final  int children;
@override final  int infants;
@override final  String travelClass;
 final  List<FlightSegment>? _multiDestSegments;
@override List<FlightSegment>? get multiDestSegments {
  final value = _multiDestSegments;
  if (value == null) return null;
  if (_multiDestSegments is EqualUnmodifiableListView) return _multiDestSegments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  double? maxPrice;

/// Create a copy of FlightSearchArguments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightSearchArgumentsCopyWith<_FlightSearchArguments> get copyWith => __$FlightSearchArgumentsCopyWithImpl<_FlightSearchArguments>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightSearchArguments&&(identical(other.departureCode, departureCode) || other.departureCode == departureCode)&&(identical(other.arrivalCode, arrivalCode) || other.arrivalCode == arrivalCode)&&(identical(other.departureDate, departureDate) || other.departureDate == departureDate)&&(identical(other.returnDate, returnDate) || other.returnDate == returnDate)&&(identical(other.adults, adults) || other.adults == adults)&&(identical(other.children, children) || other.children == children)&&(identical(other.infants, infants) || other.infants == infants)&&(identical(other.travelClass, travelClass) || other.travelClass == travelClass)&&const DeepCollectionEquality().equals(other._multiDestSegments, _multiDestSegments)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,departureCode,arrivalCode,departureDate,returnDate,adults,children,infants,travelClass,const DeepCollectionEquality().hash(_multiDestSegments),maxPrice);

@override
String toString() {
  return 'FlightSearchArguments(departureCode: $departureCode, arrivalCode: $arrivalCode, departureDate: $departureDate, returnDate: $returnDate, adults: $adults, children: $children, infants: $infants, travelClass: $travelClass, multiDestSegments: $multiDestSegments, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class _$FlightSearchArgumentsCopyWith<$Res> implements $FlightSearchArgumentsCopyWith<$Res> {
  factory _$FlightSearchArgumentsCopyWith(_FlightSearchArguments value, $Res Function(_FlightSearchArguments) _then) = __$FlightSearchArgumentsCopyWithImpl;
@override @useResult
$Res call({
 String departureCode, String arrivalCode, DateTime departureDate, DateTime? returnDate, int adults, int children, int infants, String travelClass, List<FlightSegment>? multiDestSegments, double? maxPrice
});




}
/// @nodoc
class __$FlightSearchArgumentsCopyWithImpl<$Res>
    implements _$FlightSearchArgumentsCopyWith<$Res> {
  __$FlightSearchArgumentsCopyWithImpl(this._self, this._then);

  final _FlightSearchArguments _self;
  final $Res Function(_FlightSearchArguments) _then;

/// Create a copy of FlightSearchArguments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? departureCode = null,Object? arrivalCode = null,Object? departureDate = null,Object? returnDate = freezed,Object? adults = null,Object? children = null,Object? infants = null,Object? travelClass = null,Object? multiDestSegments = freezed,Object? maxPrice = freezed,}) {
  return _then(_FlightSearchArguments(
departureCode: null == departureCode ? _self.departureCode : departureCode // ignore: cast_nullable_to_non_nullable
as String,arrivalCode: null == arrivalCode ? _self.arrivalCode : arrivalCode // ignore: cast_nullable_to_non_nullable
as String,departureDate: null == departureDate ? _self.departureDate : departureDate // ignore: cast_nullable_to_non_nullable
as DateTime,returnDate: freezed == returnDate ? _self.returnDate : returnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,adults: null == adults ? _self.adults : adults // ignore: cast_nullable_to_non_nullable
as int,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as int,infants: null == infants ? _self.infants : infants // ignore: cast_nullable_to_non_nullable
as int,travelClass: null == travelClass ? _self.travelClass : travelClass // ignore: cast_nullable_to_non_nullable
as String,multiDestSegments: freezed == multiDestSegments ? _self._multiDestSegments : multiDestSegments // ignore: cast_nullable_to_non_nullable
as List<FlightSegment>?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
