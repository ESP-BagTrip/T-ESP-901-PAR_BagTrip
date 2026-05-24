// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocationResult {

 String get name;@JsonKey(name: 'iataCode') String get iataCode; String get city;@JsonKey(name: 'countryCode') String get countryCode;@JsonKey(name: 'countryName') String get countryName;@JsonKey(name: 'subType') String get subType;
/// Create a copy of LocationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationResultCopyWith<LocationResult> get copyWith => _$LocationResultCopyWithImpl<LocationResult>(this as LocationResult, _$identity);

  /// Serializes this LocationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationResult&&(identical(other.name, name) || other.name == name)&&(identical(other.iataCode, iataCode) || other.iataCode == iataCode)&&(identical(other.city, city) || other.city == city)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.subType, subType) || other.subType == subType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iataCode,city,countryCode,countryName,subType);

@override
String toString() {
  return 'LocationResult(name: $name, iataCode: $iataCode, city: $city, countryCode: $countryCode, countryName: $countryName, subType: $subType)';
}


}

/// @nodoc
abstract mixin class $LocationResultCopyWith<$Res>  {
  factory $LocationResultCopyWith(LocationResult value, $Res Function(LocationResult) _then) = _$LocationResultCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'iataCode') String iataCode, String city,@JsonKey(name: 'countryCode') String countryCode,@JsonKey(name: 'countryName') String countryName,@JsonKey(name: 'subType') String subType
});




}
/// @nodoc
class _$LocationResultCopyWithImpl<$Res>
    implements $LocationResultCopyWith<$Res> {
  _$LocationResultCopyWithImpl(this._self, this._then);

  final LocationResult _self;
  final $Res Function(LocationResult) _then;

/// Create a copy of LocationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iataCode = null,Object? city = null,Object? countryCode = null,Object? countryName = null,Object? subType = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iataCode: null == iataCode ? _self.iataCode : iataCode // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,subType: null == subType ? _self.subType : subType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationResult].
extension LocationResultPatterns on LocationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationResult value)  $default,){
final _that = this;
switch (_that) {
case _LocationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationResult value)?  $default,){
final _that = this;
switch (_that) {
case _LocationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'iataCode')  String iataCode,  String city, @JsonKey(name: 'countryCode')  String countryCode, @JsonKey(name: 'countryName')  String countryName, @JsonKey(name: 'subType')  String subType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationResult() when $default != null:
return $default(_that.name,_that.iataCode,_that.city,_that.countryCode,_that.countryName,_that.subType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'iataCode')  String iataCode,  String city, @JsonKey(name: 'countryCode')  String countryCode, @JsonKey(name: 'countryName')  String countryName, @JsonKey(name: 'subType')  String subType)  $default,) {final _that = this;
switch (_that) {
case _LocationResult():
return $default(_that.name,_that.iataCode,_that.city,_that.countryCode,_that.countryName,_that.subType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'iataCode')  String iataCode,  String city, @JsonKey(name: 'countryCode')  String countryCode, @JsonKey(name: 'countryName')  String countryName, @JsonKey(name: 'subType')  String subType)?  $default,) {final _that = this;
switch (_that) {
case _LocationResult() when $default != null:
return $default(_that.name,_that.iataCode,_that.city,_that.countryCode,_that.countryName,_that.subType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocationResult implements LocationResult {
  const _LocationResult({required this.name, @JsonKey(name: 'iataCode') required this.iataCode, this.city = '', @JsonKey(name: 'countryCode') this.countryCode = '', @JsonKey(name: 'countryName') this.countryName = '', @JsonKey(name: 'subType') this.subType = ''});
  factory _LocationResult.fromJson(Map<String, dynamic> json) => _$LocationResultFromJson(json);

@override final  String name;
@override@JsonKey(name: 'iataCode') final  String iataCode;
@override@JsonKey() final  String city;
@override@JsonKey(name: 'countryCode') final  String countryCode;
@override@JsonKey(name: 'countryName') final  String countryName;
@override@JsonKey(name: 'subType') final  String subType;

/// Create a copy of LocationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationResultCopyWith<_LocationResult> get copyWith => __$LocationResultCopyWithImpl<_LocationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationResult&&(identical(other.name, name) || other.name == name)&&(identical(other.iataCode, iataCode) || other.iataCode == iataCode)&&(identical(other.city, city) || other.city == city)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.countryName, countryName) || other.countryName == countryName)&&(identical(other.subType, subType) || other.subType == subType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iataCode,city,countryCode,countryName,subType);

@override
String toString() {
  return 'LocationResult(name: $name, iataCode: $iataCode, city: $city, countryCode: $countryCode, countryName: $countryName, subType: $subType)';
}


}

/// @nodoc
abstract mixin class _$LocationResultCopyWith<$Res> implements $LocationResultCopyWith<$Res> {
  factory _$LocationResultCopyWith(_LocationResult value, $Res Function(_LocationResult) _then) = __$LocationResultCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'iataCode') String iataCode, String city,@JsonKey(name: 'countryCode') String countryCode,@JsonKey(name: 'countryName') String countryName,@JsonKey(name: 'subType') String subType
});




}
/// @nodoc
class __$LocationResultCopyWithImpl<$Res>
    implements _$LocationResultCopyWith<$Res> {
  __$LocationResultCopyWithImpl(this._self, this._then);

  final _LocationResult _self;
  final $Res Function(_LocationResult) _then;

/// Create a copy of LocationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iataCode = null,Object? city = null,Object? countryCode = null,Object? countryName = null,Object? subType = null,}) {
  return _then(_LocationResult(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iataCode: null == iataCode ? _self.iataCode : iataCode // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,countryCode: null == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String,countryName: null == countryName ? _self.countryName : countryName // ignore: cast_nullable_to_non_nullable
as String,subType: null == subType ? _self.subType : subType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
